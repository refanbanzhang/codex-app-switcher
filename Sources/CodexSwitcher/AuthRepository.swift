import Foundation

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
