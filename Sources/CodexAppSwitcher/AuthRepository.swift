import AppKit
import CryptoKit
import Foundation
import Network

struct AuthRepository {
    let paths: AppPaths
    private let fileManager: FileManager = .default

    func readCurrentAuth() throws -> JSONValue {
        guard fileManager.fileExists(atPath: paths.codexAuthPath.path) else {
            throw CLIError("Auth file not found at \(paths.codexAuthPath.path)")
        }
        return try readJSONValue(from: paths.codexAuthPath)
    }

    func writeCurrentAuth(_ auth: JSONValue) throws {
        let normalizedAuth = try normalizeCurrentAuth(auth)
        let parentDirectory = paths.codexAuthPath.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        try backupExistingAuthIfNeeded()

        let object = normalizedAuth.toAny()
        guard JSONSerialization.isValidJSONObject(object) else {
            throw CLIError("Auth JSON has an unsupported structure.")
        }

        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: paths.codexAuthPath, options: .atomic)
        #if canImport(Darwin)
        _ = chmod(paths.codexAuthPath.path, S_IRUSR | S_IWUSR)
        #endif
    }

    func extractAuth(from auth: JSONValue) throws -> ExtractedAuth {
        guard let tokens = authTokenObject(from: auth) else {
            throw CLIError("Auth file does not contain ChatGPT token fields.")
        }

        guard tokens["access_token"]?.stringValue != nil else {
            throw CLIError("Auth file is missing access_token.")
        }

        guard let idToken = tokens["id_token"]?.stringValue else {
            throw CLIError("Auth file is missing id_token.")
        }

        var accountID = tokens["account_id"]?.stringValue
        var email: String?

        if let claims = try? decodeJWTPayload(idToken) {
            email = claims["email"]?.stringValue
            if accountID == nil {
                accountID = claims["https://api.openai.com/auth"]?["chatgpt_account_id"]?.stringValue
            }
        }

        guard let accountID, !accountID.isEmpty else {
            throw CLIError("Unable to resolve ChatGPT account id from auth file.")
        }

        return ExtractedAuth(accountID: accountID, email: email)
    }

    func makeChatGPTAuth(from tokens: ChatGPTOAuthTokens) throws -> JSONValue {
        let claims = try decodeJWTPayload(tokens.idToken)
        let accountID = claims["https://api.openai.com/auth"]?["chatgpt_account_id"]?.stringValue

        var tokenObject: [String: JSONValue] = [
            "access_token": .string(tokens.accessToken),
            "refresh_token": .string(tokens.refreshToken),
            "id_token": .string(tokens.idToken)
        ]

        if let accountID, !accountID.isEmpty {
            tokenObject["account_id"] = .string(accountID)
        }

        var root: [String: JSONValue] = [
            "auth_mode": .string("chatgpt"),
            "last_refresh": .string(makeTimestamp(from: Date())),
            "tokens": .object(tokenObject)
        ]

        if let apiKey = tokens.apiKey, !apiKey.isEmpty {
            root["OPENAI_API_KEY"] = .string(apiKey)
        }

        return .object(root)
    }

    func currentAuthAccountID() -> String? {
        guard let auth = try? readCurrentAuth() else {
            return nil
        }
        return try? extractAuth(from: auth).accountID
    }

    private func readJSONValue(from path: URL) throws -> JSONValue {
        let data = try Data(contentsOf: path)
        let object = try JSONSerialization.jsonObject(with: data)
        return try JSONValue.from(any: object)
    }

    private func authTokenObject(from auth: JSONValue) -> [String: JSONValue]? {
        if let tokens = auth["tokens"]?.objectValue {
            return tokens
        }

        if let object = auth.objectValue,
           object["access_token"]?.stringValue != nil,
           object["id_token"]?.stringValue != nil {
            return object
        }

        return nil
    }

    private func normalizeCurrentAuth(_ auth: JSONValue) throws -> JSONValue {
        guard var root = auth.objectValue else {
            throw CLIError("Auth JSON has an unsupported structure.")
        }

        var tokens = root["tokens"]?.objectValue ?? [:]
        let topLevelTokenKeys = ["access_token", "refresh_token", "id_token", "account_id"]

        if tokens.isEmpty {
            for key in topLevelTokenKeys {
                if let value = root[key] {
                    tokens[key] = value
                }
            }
        } else {
            for key in topLevelTokenKeys where tokens[key] == nil {
                if let value = root[key] {
                    tokens[key] = value
                }
            }
        }

        guard tokens["access_token"]?.stringValue != nil else {
            throw CLIError("Auth file is missing access_token.")
        }
        guard tokens["id_token"]?.stringValue != nil else {
            throw CLIError("Auth file is missing id_token.")
        }

        root["auth_mode"] = .string(normalizedAuthMode(root["auth_mode"]))
        root["tokens"] = .object(tokens)
        for key in topLevelTokenKeys {
            root.removeValue(forKey: key)
        }
        root["last_refresh"] = .string(normalizedLastRefresh(root["last_refresh"]))
        return .object(root)
    }

    private func normalizedAuthMode(_ value: JSONValue?) -> String {
        let trimmed = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "chatgpt" : trimmed
    }

    private func normalizedLastRefresh(_ value: JSONValue?) -> String {
        if let rawValue = value?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawValue.isEmpty,
           let parsed = parseTimestamp(rawValue) {
            return makeTimestamp(from: parsed)
        }
        return makeTimestamp(from: Date())
    }

    private func parseTimestamp(_ value: String) -> Date? {
        let candidates: [String]
        if value.range(of: #"(Z|[+-]\d{2}:\d{2})$"#, options: .regularExpression) != nil {
            candidates = [value]
        } else {
            candidates = [value, "\(value)Z"]
        }

        for candidate in candidates {
            let fractionalFormatter = ISO8601DateFormatter()
            fractionalFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let parsed = fractionalFormatter.date(from: candidate) {
                return parsed
            }

            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            if let parsed = formatter.date(from: candidate) {
                return parsed
            }
        }

        return nil
    }

    private func makeTimestamp(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    private func backupExistingAuthIfNeeded() throws {
        guard fileManager.fileExists(atPath: paths.codexAuthPath.path) else {
            return
        }

        let existingData = try Data(contentsOf: paths.codexAuthPath)
        guard !existingData.isEmpty else {
            return
        }

        let existingAuth = try readJSONValue(from: paths.codexAuthPath)
        let extracted = try? extractAuth(from: existingAuth)
        let accountFragment = extracted?.accountID.replacingOccurrences(of: "/", with: "_") ?? "unknown"
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")

        try fileManager.createDirectory(at: paths.authBackupDirectory, withIntermediateDirectories: true)
        let backupURL = paths.authBackupDirectory.appendingPathComponent("\(timestamp)-\(accountFragment).json", isDirectory: false)
        try existingData.write(to: backupURL, options: .withoutOverwriting)
    }

    private func decodeJWTPayload(_ token: String) throws -> JSONValue {
        let segments = token.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count > 1 else {
            throw CLIError("id_token is not a valid JWT.")
        }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let data = Data(base64Encoded: base64) else {
            throw CLIError("Failed to decode JWT payload.")
        }

        let object = try JSONSerialization.jsonObject(with: data)
        return try JSONValue.from(any: object)
    }
}

final class OpenAIChatGPTOAuthLoginService: @unchecked Sendable {
    private enum Configuration {
        static let issuer = URL(string: "https://auth.openai.com")!
        static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
        static let originator = "codex_cli_rs"
        static let callbackPath = "/auth/callback"
        static let preferredCallbackPort: UInt16 = 1455
        static let maxPortScanOffset: UInt16 = 12
        static let scopes = "openid profile email offline_access api.connectors.read api.connectors.invoke"
    }

    private let configPath: URL
    private let session: URLSession

    init(configPath: URL, session: URLSession = .shared) {
        self.configPath = configPath
        self.session = session
    }

    func signInWithChatGPT(timeoutSeconds: TimeInterval) async throws -> ChatGPTOAuthTokens {
        let callback = OAuthCallbackBox<ChatGPTOAuthTokens>()
        let pkce = PKCECodes.make()
        let state = Self.randomBase64URL(byteCount: 32)
        let forcedWorkspaceID = resolveForcedWorkspaceID()

        let (server, port) = try makeCallbackServer(
            callback: callback,
            pkce: pkce,
            state: state,
            forcedWorkspaceID: forcedWorkspaceID
        )
        let redirectURI = Self.redirectURI(for: port)
        let authorizeURL = try makeAuthorizeURL(
            redirectURI: redirectURI,
            pkce: pkce,
            state: state,
            forcedWorkspaceID: forcedWorkspaceID
        )

        server.start()
        defer { server.stop() }

        guard NSWorkspace.shared.open(authorizeURL) else {
            throw CLIError("Failed to open browser for ChatGPT sign-in.")
        }

        return try await callback.wait(
            timeoutSeconds: timeoutSeconds,
            timeoutError: CLIError("Timed out waiting for ChatGPT sign-in.")
        )
    }

    private func makeCallbackServer(
        callback: OAuthCallbackBox<ChatGPTOAuthTokens>,
        pkce: PKCECodes,
        state: String,
        forcedWorkspaceID: String?
    ) throws -> (SimpleHTTPServer, UInt16) {
        var candidatePort = Configuration.preferredCallbackPort
        let maxPort = Configuration.preferredCallbackPort + Configuration.maxPortScanOffset
        var lastError: Error?

        while candidatePort <= maxPort {
            do {
                let redirectURI = Self.redirectURI(for: candidatePort)
                let server = try SimpleHTTPServer(port: candidatePort) { [session] request in
                    await Self.handleCallback(
                        request: request,
                        session: session,
                        redirectURI: redirectURI,
                        pkce: pkce,
                        state: state,
                        forcedWorkspaceID: forcedWorkspaceID,
                        callback: callback
                    )
                }
                return (server, candidatePort)
            } catch {
                lastError = error
                candidatePort += 1
            }
        }

        throw lastError ?? CLIError("Failed to start callback server for ChatGPT sign-in.")
    }

    private static func handleCallback(
        request: HTTPRequest,
        session: URLSession,
        redirectURI: String,
        pkce: PKCECodes,
        state: String,
        forcedWorkspaceID: String?,
        callback: OAuthCallbackBox<ChatGPTOAuthTokens>
    ) async -> HTTPResponse {
        guard request.method == "GET" else {
            return .text(statusCode: 405, text: "Method Not Allowed")
        }

        switch request.path {
        case Configuration.callbackPath:
            let params = [String: String](uniqueKeysWithValues: request.queryItems.compactMap { item in
                guard let value = item.value else { return nil }
                return (item.name, value)
            })

            guard params["state"] == state else {
                let error = CLIError("State mismatch during ChatGPT sign-in.")
                callback.fail(error)
                return .html(statusCode: 400, body: errorPageHTML(message: error.message))
            }

            if let code = params["code"], !code.isEmpty {
                do {
                    let tokens = try await exchangeCodeForTokens(
                        session: session,
                        redirectURI: redirectURI,
                        pkce: pkce,
                        code: code,
                        forcedWorkspaceID: forcedWorkspaceID
                    )
                    callback.succeed(tokens)
                    return .html(statusCode: 200, body: successPageHTML())
                } catch {
                    callback.fail(error)
                    return .html(statusCode: 500, body: errorPageHTML(message: error.localizedDescription))
                }
            }

            if let errorCode = params["error"] {
                let description = params["error_description"]?.trimmingCharacters(in: .whitespacesAndNewlines)
                let message = description?.isEmpty == false ? description! : errorCode
                let authError = CLIError("ChatGPT sign-in failed: \(message)")
                callback.fail(authError)
                return .html(statusCode: 401, body: errorPageHTML(message: authError.message))
            }

            let error = CLIError("ChatGPT sign-in callback did not include a code.")
            callback.fail(error)
            return .html(statusCode: 400, body: errorPageHTML(message: error.message))
        case "/cancel":
            let error = CLIError("ChatGPT sign-in was cancelled.")
            callback.fail(error)
            return .html(statusCode: 200, body: errorPageHTML(message: error.message))
        default:
            return .text(statusCode: 404, text: "Not Found")
        }
    }

    private static func exchangeCodeForTokens(
        session: URLSession,
        redirectURI: String,
        pkce: PKCECodes,
        code: String,
        forcedWorkspaceID: String?
    ) async throws -> ChatGPTOAuthTokens {
        var request = URLRequest(url: endpointURL("/oauth/token"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncodedBody([
            ("grant_type", "authorization_code"),
            ("code", code),
            ("redirect_uri", redirectURI),
            ("client_id", Configuration.clientID),
            ("code_verifier", pkce.codeVerifier)
        ])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CLIError("Invalid response while exchanging ChatGPT auth code.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let detail = body.isEmpty ? "HTTP \(httpResponse.statusCode)" : String(body.prefix(200))
            throw CLIError("ChatGPT token exchange failed: \(detail)")
        }

        let tokenResponse = try JSONDecoder().decode(TokenExchangeResponse.self, from: data)
        if let forcedWorkspaceID {
            let accountID = try extractAccountID(fromIDToken: tokenResponse.idToken)
            guard accountID == forcedWorkspaceID else {
                throw CLIError("Signed in to the wrong workspace. Expected \(forcedWorkspaceID).")
            }
        }

        let apiKey = try? await exchangeIDTokenForAPIKey(session: session, idToken: tokenResponse.idToken)
        return ChatGPTOAuthTokens(
            accessToken: tokenResponse.accessToken,
            refreshToken: tokenResponse.refreshToken,
            idToken: tokenResponse.idToken,
            apiKey: apiKey
        )
    }

    private static func exchangeIDTokenForAPIKey(session: URLSession, idToken: String) async throws -> String {
        var request = URLRequest(url: endpointURL("/oauth/token"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formEncodedBody([
            ("grant_type", "urn:ietf:params:oauth:grant-type:token-exchange"),
            ("client_id", Configuration.clientID),
            ("requested_token", "openai-api-key"),
            ("subject_token", idToken),
            ("subject_token_type", "urn:ietf:params:oauth:token-type:id_token")
        ])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw CLIError("Failed to exchange id_token for API key.")
        }

        let payload = try JSONDecoder().decode(APIKeyExchangeResponse.self, from: data)
        return payload.accessToken
    }

    private func makeAuthorizeURL(
        redirectURI: String,
        pkce: PKCECodes,
        state: String,
        forcedWorkspaceID: String?
    ) throws -> URL {
        var components = URLComponents(url: Self.endpointURL("/oauth/authorize"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: Configuration.scopes),
            URLQueryItem(name: "code_challenge", value: pkce.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "id_token_add_organizations", value: "true"),
            URLQueryItem(name: "codex_cli_simplified_flow", value: "true"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "originator", value: Configuration.originator)
        ]

        if let forcedWorkspaceID, !forcedWorkspaceID.isEmpty {
            components?.queryItems?.append(URLQueryItem(name: "allowed_workspace_id", value: forcedWorkspaceID))
        }

        guard let url = components?.url else {
            throw CLIError("Failed to create ChatGPT authorize URL.")
        }
        return url
    }

    private func resolveForcedWorkspaceID() -> String? {
        guard let raw = try? String(contentsOf: configPath, encoding: .utf8), !raw.isEmpty else {
            return nil
        }

        for line in raw.split(whereSeparator: \.isNewline) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("forced_chatgpt_workspace_id") else { continue }
            guard let equalIndex = trimmed.firstIndex(of: "=") else { continue }
            let value = trimmed[trimmed.index(after: equalIndex)...]
                .trimmingCharacters(in: .whitespaces)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            if !value.isEmpty {
                return value
            }
        }

        return nil
    }

    private static func extractAccountID(fromIDToken idToken: String) throws -> String {
        let segments = idToken.split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count > 1 else {
            throw CLIError("id_token is not a valid JWT.")
        }

        var base64 = String(segments[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }

        guard let payload = Data(base64Encoded: base64) else {
            throw CLIError("Failed to decode id_token while checking workspace.")
        }

        let object = try JSONSerialization.jsonObject(with: payload)
        guard let json = try? JSONValue.from(any: object),
              let accountID = json["https://api.openai.com/auth"]?["chatgpt_account_id"]?.stringValue,
              !accountID.isEmpty else {
            throw CLIError("Unable to resolve chatgpt_account_id from id_token.")
        }
        return accountID
    }

    private static func formEncodedBody(_ items: [(String, String)]) -> Data {
        let encoded = items
            .map { key, value in
                "\(percentEncode(key))=\(percentEncode(value))"
            }
            .joined(separator: "&")
        return Data(encoded.utf8)
    }

    private static func percentEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .oauthFormAllowed) ?? value
    }

    private static func endpointURL(_ path: String) -> URL {
        guard let url = URL(string: path, relativeTo: Configuration.issuer)?.absoluteURL else {
            return Configuration.issuer
        }
        return url
    }

    private static func redirectURI(for port: UInt16) -> String {
        "http://localhost:\(port)\(Configuration.callbackPath)"
    }

    fileprivate static func randomBase64URL(byteCount: Int) -> String {
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: .min ... .max) }
        let data = Data(bytes)
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func successPageHTML() -> Data {
        Data("<html><head><meta charset=\"utf-8\"><title>codex-app-switcher</title></head><body style=\"font-family:-apple-system,BlinkMacSystemFont,sans-serif;padding:32px;\"><h2>Sign-in complete</h2><p>You can return to codex-app-switcher.</p></body></html>".utf8)
    }

    private static func errorPageHTML(message: String) -> Data {
        let escapedMessage = htmlEscape(message)
        return Data("<html><head><meta charset=\"utf-8\"><title>codex-app-switcher</title></head><body style=\"font-family:-apple-system,BlinkMacSystemFont,sans-serif;padding:32px;\"><h2>Sign-in failed</h2><p>\(escapedMessage)</p></body></html>".utf8)
    }

    private static func htmlEscape(_ value: String) -> String {
        var escaped = value
        let mappings = [
            ("&", "&amp;"),
            ("<", "&lt;"),
            (">", "&gt;"),
            ("\"", "&quot;"),
            ("'", "&#39;")
        ]
        for (source, target) in mappings {
            escaped = escaped.replacingOccurrences(of: source, with: target)
        }
        return escaped
    }
}

private struct PKCECodes {
    var codeVerifier: String
    var codeChallenge: String

    static func make() -> PKCECodes {
        let verifier = OpenAIChatGPTOAuthLoginService.randomBase64URL(byteCount: 64)
        let digest = SHA256.hash(data: Data(verifier.utf8))
        let challenge = Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return PKCECodes(codeVerifier: verifier, codeChallenge: challenge)
    }
}

private final class OAuthCallbackBox<Value: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Value, any Error>?
    private var result: Result<Value, any Error>?

    func wait(timeoutSeconds: TimeInterval, timeoutError: Error) async throws -> Value {
        let timeoutTask = Task { [weak self] in
            let nanoseconds = UInt64(max(timeoutSeconds, 0) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: nanoseconds)
            self?.fail(timeoutError)
        }
        defer { timeoutTask.cancel() }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Value, any Error>) in
            lock.lock()
            if let result {
                lock.unlock()
                resume(continuation, with: result)
                return
            }
            self.continuation = continuation
            lock.unlock()
        }
    }

    func succeed(_ value: Value) {
        resolve(.success(value))
    }

    func fail(_ error: Error) {
        resolve(.failure(error))
    }

    private func resolve(_ result: Result<Value, any Error>) {
        lock.lock()
        guard self.result == nil else {
            lock.unlock()
            return
        }
        self.result = result
        let continuation = self.continuation
        self.continuation = nil
        lock.unlock()
        if let continuation {
            resume(continuation, with: result)
        }
    }

    private func resume(_ continuation: CheckedContinuation<Value, any Error>, with result: Result<Value, any Error>) {
        switch result {
        case .success(let value):
            continuation.resume(returning: value)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

private struct TokenExchangeResponse: Decodable {
    let idToken: String
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

private struct APIKeyExchangeResponse: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct HTTPRequest {
    var method: String
    var target: String
    var path: String
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var body: Data
}

struct HTTPResponse {
    var statusCode: Int
    var headers: [String: String]
    var body: Data

    static func text(statusCode: Int, text: String) -> HTTPResponse {
        HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "text/plain; charset=utf-8"],
            body: Data(text.utf8)
        )
    }

    static func html(statusCode: Int, body: Data) -> HTTPResponse {
        HTTPResponse(
            statusCode: statusCode,
            headers: ["Content-Type": "text/html; charset=utf-8"],
            body: body
        )
    }
}

final class SimpleHTTPServer: @unchecked Sendable {
    typealias RequestHandler = @Sendable (HTTPRequest) async -> HTTPResponse

    private let listener: NWListener
    private let queue: DispatchQueue
    private let handler: RequestHandler

    init(port: UInt16, handler: @escaping RequestHandler) throws {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw CLIError("Invalid callback port \(port).")
        }
        self.listener = try NWListener(using: .tcp, on: nwPort)
        self.queue = DispatchQueue(label: "codex.switcher.oauth.listener", qos: .userInitiated)
        self.handler = handler
    }

    func start() {
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection: connection)
        }
        listener.start(queue: queue)
    }

    func stop() {
        listener.cancel()
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        readRequest(on: connection, buffer: Data())
    }

    private func readRequest(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }

            if error != nil {
                connection.cancel()
                return
            }

            var working = buffer
            if let data, !data.isEmpty {
                working.append(data)
            }

            if let request = Self.parseRequest(from: working) {
                Task {
                    let response = await self.handler(request)
                    self.send(response: response, on: connection)
                }
                return
            }

            if isComplete {
                self.send(response: .text(statusCode: 400, text: "Bad Request"), on: connection)
                return
            }

            self.readRequest(on: connection, buffer: working)
        }
    }

    private func send(response: HTTPResponse, on connection: NWConnection) {
        let payload = Self.encode(response: response)
        connection.send(content: payload, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func parseRequest(from data: Data) -> HTTPRequest? {
        guard let headerRange = data.range(of: Data("\r\n\r\n".utf8)) else {
            return nil
        }

        let headerData = data.subdata(in: 0..<headerRange.lowerBound)
        guard let headerText = String(data: headerData, encoding: .utf8) else {
            return nil
        }

        let lines = headerText.split(separator: "\r\n", omittingEmptySubsequences: false)
        guard let requestLine = lines.first else {
            return nil
        }

        let requestParts = requestLine.split(separator: " ")
        guard requestParts.count >= 2 else {
            return nil
        }

        let method = String(requestParts[0]).uppercased()
        let target = String(requestParts[1])
        let components = URLComponents(string: target)
        let path = components?.path.isEmpty == false ? (components?.path ?? "/") : (target.split(separator: "?").first.map(String.init) ?? "/")
        let queryItems = components?.queryItems ?? []

        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let index = line.firstIndex(of: ":") else { continue }
            let name = line[..<index].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = line[line.index(after: index)...].trimmingCharacters(in: .whitespacesAndNewlines)
            headers[name] = value
        }

        let contentLength = Int(headers["content-length"] ?? "0") ?? 0
        let bodyStart = headerRange.upperBound
        let expectedEnd = bodyStart + contentLength
        guard data.count >= expectedEnd else {
            return nil
        }

        let body = contentLength == 0 ? Data() : data.subdata(in: bodyStart..<expectedEnd)
        return HTTPRequest(
            method: method,
            target: target,
            path: path,
            queryItems: queryItems,
            headers: headers,
            body: body
        )
    }

    private static func encode(response: HTTPResponse) -> Data {
        let reason = reasonPhrase(for: response.statusCode)
        var headerLines: [String] = [
            "HTTP/1.1 \(response.statusCode) \(reason)",
            "Connection: close",
            "Content-Length: \(response.body.count)"
        ]

        for (key, value) in response.headers {
            headerLines.append("\(key): \(value)")
        }
        headerLines.append("\r\n")

        var output = Data(headerLines.joined(separator: "\r\n").utf8)
        output.append(response.body)
        return output
    }

    private static func reasonPhrase(for statusCode: Int) -> String {
        switch statusCode {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 404: return "Not Found"
        case 405: return "Method Not Allowed"
        case 500: return "Internal Server Error"
        default: return "HTTP"
        }
    }
}

private extension CharacterSet {
    static let oauthFormAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
}
