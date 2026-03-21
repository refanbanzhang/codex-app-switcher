import Foundation

struct AccountService {
    let authRepository: AuthRepository
    let storeRepository: StoreRepository

    func syncCurrentAuthAccountOnStartup() throws {
        let authJSON = try authRepository.readCurrentAuth()
        _ = try upsertAccount(authJSON: authJSON)
    }

    func importCurrentAuth() throws -> AccountSummary {
        let authJSON = try authRepository.readCurrentAuth()
        return try upsertAccount(authJSON: authJSON)
    }

    func listAccounts() throws -> [AccountSummary] {
        let store = try storeRepository.load()
        let currentAccountID = authRepository.currentAuthAccountID() ?? store.currentSelection?.accountID

        return store.accounts
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

    func currentAccount() throws -> AccountSummary? {
        try listAccounts().first(where: \.isCurrent)
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
            sourceDeviceID: "codex-switcher"
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
}
