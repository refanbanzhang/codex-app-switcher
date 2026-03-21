import Foundation

struct AccountService: @unchecked Sendable {
    let authRepository: AuthRepository
    let storeRepository: StoreRepository
    let loginService: OpenAIChatGPTOAuthLoginService
    let usageService: ChatGPTUsageService

    func syncCurrentAuthAccountOnStartup() throws {
        let authJSON = try authRepository.readCurrentAuth()
        _ = try upsertAccount(authJSON: authJSON)
    }

    func refreshUsageForAllAccounts() async throws -> [AccountSummary] {
        var store = try storeRepository.loadOrEmpty()
        let currentAccountID = authRepository.currentAuthAccountID() ?? store.currentSelection?.accountID

        guard !store.accounts.isEmpty else {
            return []
        }

        var didChangeStore = false
        let now = Int64(Date().timeIntervalSince1970)

        for index in store.accounts.indices {
            do {
                let refreshed = try await usageService.refreshAccount(from: store.accounts[index].authJSON)

                if store.accounts[index].authJSON != refreshed.authJSON {
                    store.accounts[index].authJSON = refreshed.authJSON
                    didChangeStore = true

                    if store.accounts[index].accountID == currentAccountID {
                        try? authRepository.writeCurrentAuth(refreshed.authJSON)
                    }
                }

                store.accounts[index].usage = refreshed.usage
                let trimmedPlanType = refreshed.planType?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !trimmedPlanType.isEmpty {
                    store.accounts[index].planType = trimmedPlanType
                }
                store.accounts[index].updatedAt = now
                didChangeStore = true
            } catch {
                continue
            }
        }

        if didChangeStore {
            try storeRepository.save(store)
        }

        return summaries(from: store, currentAccountID: currentAccountID)
    }

    func addAccountViaLogin(timeoutSeconds: TimeInterval = 10 * 60) async throws -> AccountSummary {
        try preserveCurrentAuthBeforeSwitch()
        let tokens = try await loginService.signInWithChatGPT(timeoutSeconds: timeoutSeconds)
        let authJSON = try authRepository.makeChatGPTAuth(from: tokens)
        try authRepository.writeCurrentAuth(authJSON)

        let summary = try upsertAccount(authJSON: authJSON)
        var store = try storeRepository.loadOrEmpty()
        store.currentSelection = CurrentAccountSelection(
            accountID: summary.accountID,
            selectedAt: Int64(Date().timeIntervalSince1970 * 1_000),
            sourceDeviceID: "codex-app-switcher"
        )
        try storeRepository.save(store)

        return AccountSummary(
            id: summary.id,
            label: summary.label,
            email: summary.email,
            accountID: summary.accountID,
            planType: summary.planType,
            teamName: summary.teamName,
            isCurrent: true
        )
    }

    func switchAccount(identifier: String) throws -> AccountSummary {
        try preserveCurrentAuthBeforeSwitch()
        var store = try storeRepository.load()
        guard let account = store.accounts.first(where: { $0.id == identifier || $0.accountID == identifier }) else {
            throw CLIError("Account not found for identifier: \(identifier)")
        }

        let extracted = try authRepository.extractAuth(from: account.authJSON)
        try authRepository.writeCurrentAuth(account.authJSON)

        store.currentSelection = CurrentAccountSelection(
            accountID: extracted.accountID,
            selectedAt: Int64(Date().timeIntervalSince1970 * 1_000),
            sourceDeviceID: "codex-app-switcher"
        )
        try storeRepository.save(store)

        return AccountSummary(
            id: account.id,
            label: account.label,
            email: account.email,
            accountID: account.accountID,
            planType: account.planType,
            teamName: account.teamName,
            usage: account.usage,
            isCurrent: true
        )
    }

    func deleteAccount(identifier: String) throws -> AccountSummary {
        var store = try storeRepository.load()
        let currentAccountID = authRepository.currentAuthAccountID() ?? store.currentSelection?.accountID

        guard let index = store.accounts.firstIndex(where: { $0.id == identifier || $0.accountID == identifier }) else {
            throw CLIError("Account not found for identifier: \(identifier)")
        }

        let account = store.accounts[index]
        if account.accountID == currentAccountID {
            throw CLIError("不能删除当前账号，请先切换到其他账号。")
        }

        store.accounts.remove(at: index)
        if store.currentSelection?.accountID == account.accountID {
            store.currentSelection = nil
        }
        try storeRepository.save(store)

        return AccountSummary(
            id: account.id,
            label: account.label,
            email: account.email,
            accountID: account.accountID,
            planType: account.planType,
            teamName: account.teamName,
            usage: account.usage,
            isCurrent: false
        )
    }

    func exportAccountsJSON(to outputURL: URL? = nil) throws -> AccountsExportResult {
        try preserveCurrentAuthBeforeSwitch()
        let store = try storeRepository.loadOrEmpty()
        guard !store.accounts.isEmpty else {
            throw CLIError("没有可导出的账号。")
        }

        let destination = outputURL ?? defaultExportURL()
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(store)
        try data.write(to: destination, options: .atomic)

        return AccountsExportResult(fileURL: destination, accountCount: store.accounts.count)
    }

    func importAccountsJSON(from inputURL: URL) throws -> AccountsImportResult {
        let canAccess = inputURL.startAccessingSecurityScopedResource()
        defer {
            if canAccess {
                inputURL.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: inputURL)
        let decoder = JSONDecoder()
        let importedStore: AccountStore
        if let decodedStore = try? decoder.decode(AccountStore.self, from: data) {
            importedStore = decodedStore
        } else if let decodedAccounts = try? decoder.decode([StoredAccount].self, from: data) {
            importedStore = AccountStore(version: 1, accounts: decodedAccounts, currentSelection: nil)
        } else {
            throw CLIError("导入文件格式不正确，请选择由导出功能生成的 JSON。")
        }

        guard !importedStore.accounts.isEmpty else {
            throw CLIError("导入文件没有账号数据。")
        }

        var store = try storeRepository.loadOrEmpty()
        let now = Int64(Date().timeIntervalSince1970)
        var addedCount = 0
        var updatedCount = 0

        for rawAccount in importedStore.accounts {
            let account = normalizedImportedAccount(rawAccount, now: now)
            let accountID = account.accountID.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !accountID.isEmpty else {
                continue
            }

            if let existingIndex = store.accounts.firstIndex(where: { $0.accountID == accountID }) {
                let existing = store.accounts[existingIndex]
                store.accounts[existingIndex] = StoredAccount(
                    id: existing.id,
                    label: account.label.isEmpty ? existing.label : account.label,
                    email: account.email ?? existing.email,
                    accountID: existing.accountID,
                    planType: account.planType ?? existing.planType,
                    teamName: account.teamName ?? existing.teamName,
                    usage: account.usage ?? existing.usage,
                    authJSON: account.authJSON,
                    addedAt: existing.addedAt,
                    updatedAt: now
                )
                updatedCount += 1
            } else {
                store.accounts.append(account)
                addedCount += 1
            }
        }

        if addedCount == 0, updatedCount == 0 {
            throw CLIError("导入文件没有可用账号数据。")
        }

        try storeRepository.save(store)
        return AccountsImportResult(
            addedCount: addedCount,
            updatedCount: updatedCount,
            totalCount: addedCount + updatedCount
        )
    }

    private func defaultExportURL(now: Date = Date()) -> URL {
        let fileManager = FileManager.default
        let directory = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let fileName = "codex-accounts-export-\(formatter.string(from: now)).json"
        return directory.appendingPathComponent(fileName, isDirectory: false)
    }

    private func normalizedImportedAccount(_ account: StoredAccount, now: Int64) -> StoredAccount {
        let trimmedLabel = account.label.trimmingCharacters(in: .whitespacesAndNewlines)
        let safeLabel: String
        if trimmedLabel.isEmpty {
            if let email = account.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty {
                safeLabel = email
            } else {
                safeLabel = "Codex \(String(account.accountID.prefix(8)))"
            }
        } else {
            safeLabel = trimmedLabel
        }

        return StoredAccount(
            id: account.id.isEmpty ? UUID().uuidString : account.id,
            label: safeLabel,
            email: account.email,
            accountID: account.accountID,
            planType: account.planType,
            teamName: account.teamName,
            usage: account.usage,
            authJSON: account.authJSON,
            addedAt: account.addedAt > 0 ? account.addedAt : now,
            updatedAt: now
        )
    }

    private func preserveCurrentAuthBeforeSwitch() throws {
        guard let currentAuth = try? authRepository.readCurrentAuth() else {
            return
        }

        _ = try? upsertAccount(authJSON: currentAuth)
    }

    @discardableResult
    private func upsertAccount(authJSON: JSONValue) throws -> AccountSummary {
        let extracted = try authRepository.extractAuth(from: authJSON)
        var store = try storeRepository.loadOrEmpty()
        let now = Int64(Date().timeIntervalSince1970)

        if let index = store.accounts.firstIndex(where: { $0.accountID == extracted.accountID }) {
            store.accounts[index].label = store.accounts[index].label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? (extracted.email ?? "Codex \(String(extracted.accountID.prefix(8)))")
                : store.accounts[index].label
            store.accounts[index].email = extracted.email
            store.accounts[index].authJSON = authJSON
            store.accounts[index].updatedAt = now
        } else {
            let label = extracted.email ?? "Codex \(String(extracted.accountID.prefix(8)))"
            store.accounts.append(
                StoredAccount(
                    id: UUID().uuidString,
                    label: label,
                    email: extracted.email,
                    accountID: extracted.accountID,
                    planType: nil,
                    teamName: nil,
                    usage: nil,
                    authJSON: authJSON,
                    addedAt: now,
                    updatedAt: now
                )
            )
        }

        try storeRepository.save(store)
        let currentAccountID = authRepository.currentAuthAccountID() ?? store.currentSelection?.accountID
        let saved = store.accounts.first(where: { $0.accountID == extracted.accountID })!
        return AccountSummary(
            id: saved.id,
            label: saved.label,
            email: saved.email,
            accountID: saved.accountID,
            planType: saved.planType,
            teamName: saved.teamName,
            usage: saved.usage,
            isCurrent: saved.accountID == currentAccountID
        )
    }

    private func summaries(from store: AccountStore, currentAccountID: String?) -> [AccountSummary] {
        store.accounts
            .map { account in
                AccountSummary(
                    id: account.id,
                    label: account.label,
                    email: account.email,
                    accountID: account.accountID,
                    planType: account.planType,
                    teamName: account.teamName,
                    usage: account.usage,
                    isCurrent: account.accountID == currentAccountID
                )
            }
            .sorted { left, right in
                if left.isCurrent != right.isCurrent {
                    return left.isCurrent
                }
                return left.displayName.localizedCaseInsensitiveCompare(right.displayName) == .orderedAscending
            }
    }
}

struct AccountsExportResult {
    let fileURL: URL
    let accountCount: Int
}

struct AccountsImportResult {
    let addedCount: Int
    let updatedCount: Int
    let totalCount: Int
}

struct RefreshedAccountUsage {
    var authJSON: JSONValue
    var usage: AccountUsage
    var planType: String?
}

final class ChatGPTUsageService: @unchecked Sendable {
    private enum Configuration {
        static let baseURL = URL(string: "https://chatgpt.com")!
        static let clientID = "app_EMoamEEZ73f0CkXaXp7hrann"
    }

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func refreshAccount(from authJSON: JSONValue) async throws -> RefreshedAccountUsage {
        let payload = try AuthPayload(authJSON: authJSON)

        do {
            return try await fetchUsage(payload: payload, authJSON: authJSON)
        } catch let error as UsageRequestError where error.isUnauthorized {
            let refreshedTokens = try await refreshTokens(using: payload)
            let refreshedAuthJSON = try merge(authJSON: authJSON, with: refreshedTokens)
            let refreshedPayload = try AuthPayload(authJSON: refreshedAuthJSON)
            return try await fetchUsage(payload: refreshedPayload, authJSON: refreshedAuthJSON)
        }
    }

    private func fetchUsage(payload: AuthPayload, authJSON: JSONValue) async throws -> RefreshedAccountUsage {
        var request = URLRequest(url: Self.endpointURL("/backend-api/wham/usage"))
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("Bearer \(payload.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let accountID = payload.accountID, !accountID.isEmpty {
            request.setValue(accountID, forHTTPHeaderField: "ChatGPT-Account-Id")
        }

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CLIError("Failed to refresh account usage.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UsageRequestError(statusCode: httpResponse.statusCode, responseData: data)
        }

        let responsePayload = try JSONDecoder().decode(ChatGPTUsageResponse.self, from: data)
        let usage = mapUsage(from: responsePayload)
        return RefreshedAccountUsage(authJSON: authJSON, usage: usage, planType: responsePayload.planType)
    }

    private func refreshTokens(using payload: AuthPayload) async throws -> RefreshedTokenResponse {
        var request = URLRequest(url: Self.authEndpointURL("/oauth/token"))
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.formEncodedBody([
            ("grant_type", "refresh_token"),
            ("client_id", Configuration.clientID),
            ("refresh_token", payload.refreshToken)
        ])

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CLIError("Failed to refresh ChatGPT access token.")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let detail = body.isEmpty ? "HTTP \(httpResponse.statusCode)" : String(body.prefix(200))
            throw CLIError("Failed to refresh ChatGPT access token: \(detail)")
        }

        return try JSONDecoder().decode(RefreshedTokenResponse.self, from: data)
    }

    private func merge(authJSON: JSONValue, with refreshedTokens: RefreshedTokenResponse) throws -> JSONValue {
        guard var root = authJSON.objectValue else {
            throw CLIError("Auth JSON has an unsupported structure.")
        }

        var tokens = root["tokens"]?.objectValue ?? [:]
        tokens["access_token"] = .string(refreshedTokens.accessToken)

        if let refreshToken = refreshedTokens.refreshToken, !refreshToken.isEmpty {
            tokens["refresh_token"] = .string(refreshToken)
        }

        if let idToken = refreshedTokens.idToken, !idToken.isEmpty {
            tokens["id_token"] = .string(idToken)
        }

        root["tokens"] = .object(tokens)
        root["last_refresh"] = .string(Self.isoTimestamp(from: Date()))
        return .object(root)
    }

    private func mapUsage(from response: ChatGPTUsageResponse) -> AccountUsage {
        let windows = [
            response.rateLimit?.primaryWindow,
            response.rateLimit?.secondaryWindow
        ].compactMap { $0 }

        var fiveHour: UsageWindow?
        var oneWeek: UsageWindow?

        for window in windows {
            let mappedWindow = UsageWindow(
                resetAt: window.resetAt,
                usedPercent: window.usedPercent
            )

            switch window.limitWindowSeconds ?? 0 {
            case ..<86_400:
                fiveHour = mappedWindow
            case 604_800:
                oneWeek = mappedWindow
            default:
                if oneWeek == nil {
                    oneWeek = mappedWindow
                }
            }
        }

        return AccountUsage(
            fiveHour: fiveHour,
            oneWeek: oneWeek,
            planType: response.planType
        )
    }

    private static func endpointURL(_ path: String) -> URL {
        URL(string: path, relativeTo: Configuration.baseURL)?.absoluteURL ?? Configuration.baseURL
    }

    private static func authEndpointURL(_ path: String) -> URL {
        URL(string: "https://auth.openai.com\(path)") ?? Configuration.baseURL
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
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    private static func isoTimestamp(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}

private struct AuthPayload {
    var accessToken: String
    var refreshToken: String
    var accountID: String?

    init(authJSON: JSONValue) throws {
        guard let tokens = authJSON["tokens"]?.objectValue else {
            throw CLIError("Auth file does not contain token information.")
        }

        guard let accessToken = tokens["access_token"]?.stringValue, !accessToken.isEmpty else {
            throw CLIError("Auth file is missing access_token.")
        }

        guard let refreshToken = tokens["refresh_token"]?.stringValue, !refreshToken.isEmpty else {
            throw CLIError("Auth file is missing refresh_token.")
        }

        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.accountID = tokens["account_id"]?.stringValue
    }
}

private struct UsageRequestError: Error {
    var statusCode: Int
    var responseData: Data

    var isUnauthorized: Bool {
        statusCode == 401 || statusCode == 403
    }
}

private struct ChatGPTUsageResponse: Decodable {
    var planType: String?
    var rateLimit: ChatGPTUsageLimitGroup?

    enum CodingKeys: String, CodingKey {
        case planType = "plan_type"
        case rateLimit = "rate_limit"
    }
}

private struct ChatGPTUsageLimitGroup: Decodable {
    var primaryWindow: ChatGPTUsageWindow?
    var secondaryWindow: ChatGPTUsageWindow?

    enum CodingKeys: String, CodingKey {
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

private struct ChatGPTUsageWindow: Decodable {
    var resetAt: Int64?
    var usedPercent: Double?
    var limitWindowSeconds: Int64?

    enum CodingKeys: String, CodingKey {
        case resetAt = "reset_at"
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
    }
}

private struct RefreshedTokenResponse: Decodable {
    var accessToken: String
    var refreshToken: String?
    var idToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case idToken = "id_token"
    }
}
