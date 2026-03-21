import Foundation

struct CLI {
    private let accountService: AccountService

    init() throws {
        let paths = try AppPaths.live()
        let authRepository = AuthRepository(paths: paths)
        let storeRepository = StoreRepository(paths: paths)
        let loginService = OpenAIChatGPTOAuthLoginService(configPath: paths.codexConfigPath)
        self.accountService = AccountService(
            authRepository: authRepository,
            storeRepository: storeRepository,
            loginService: loginService,
            usageService: ChatGPTUsageService()
        )
    }

    func run(arguments: [String]) throws {
        guard let command = arguments.first else {
            print(Self.helpText)
            return
        }

        switch command {
        case "list":
            try listAccounts()
        case "current":
            if let current = try accountService.currentAccount() {
                print("\(current.displayName) [\(current.accountID)]")
            } else {
                print("No current account.")
            }
        case "switch":
            let remaining = Array(arguments.dropFirst())
            guard let identifier = remaining.first else {
                throw CLIError("Missing account identifier. Use store ID or account ID.")
            }
            let summary = try accountService.switchAccount(identifier: identifier)
            print("Switched to \(summary.displayName) [\(summary.accountID)]")
        case "delete":
            let remaining = Array(arguments.dropFirst())
            guard let identifier = remaining.first else {
                throw CLIError("Missing account identifier. Use store ID or account ID.")
            }
            let summary = try accountService.deleteAccount(identifier: identifier)
            print("Deleted \(summary.displayName) [\(summary.accountID)]")
        case "help", "--help", "-h":
            print(Self.helpText)
        default:
            throw CLIError("Unknown command: \(command)\n\n\(Self.helpText)")
        }
    }

    private func listAccounts() throws {
        let accounts = try accountService.listAccounts()
        if accounts.isEmpty {
            print("No accounts found in Copool store.")
            return
        }

        for account in accounts {
            let marker = account.isCurrent ? "*" : " "
            let email = account.email ?? "-"
            let plan = account.effectivePlanType ?? "-"
            let team = account.teamName ?? "-"
            let usage = usageSummary(for: account)
            print("\(marker) \(account.id)  \(account.displayName)  \(email)  \(account.accountID)  \(plan)  \(team)  \(usage)")
        }
    }

    private func usageSummary(for account: AccountSummary) -> String {
        let fiveHour = percentageText(for: account.usage?.fiveHour)
        let oneWeek = percentageText(for: account.usage?.oneWeek)
        return "5h剩余 \(fiveHour) / 1w剩余 \(oneWeek)"
    }

    private func percentageText(for window: UsageWindow?) -> String {
        guard let remaining = window?.remainingPercent else {
            return "-"
        }
        return "\(Int(remaining.rounded()))%"
    }

    private static let helpText = """
    codex-switcher

    Commands:
      list
      current
      switch IDENTIFIER
      delete IDENTIFIER

    Notes:
      - Accounts are read from Copool: ~/Library/Application Support/CodexToolsSwift/accounts.json
      - Current Codex auth is read from and written to ~/.codex/auth.json
      - switch also updates currentSelection in the Copool store
      - delete removes the saved account from the Copool store
      - IDENTIFIER can be the stored account id or the ChatGPT account id
    """
}

struct CLIError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}
