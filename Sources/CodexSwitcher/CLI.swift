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
                print("\(current.maskedDisplayName) [\(current.accountID)]")
            } else {
                print("No current account.")
            }
        case "switch":
            let remaining = Array(arguments.dropFirst())
            guard let identifier = remaining.first else {
                throw CLIError("Missing account identifier. Use store ID or account ID.")
            }
            let summary = try accountService.switchAccount(identifier: identifier)
            print("Switched to \(summary.maskedDisplayName) [\(summary.accountID)]")
        case "delete":
            let remaining = Array(arguments.dropFirst())
            guard let identifier = remaining.first else {
                throw CLIError("Missing account identifier. Use store ID or account ID.")
            }
            let summary = try accountService.deleteAccount(identifier: identifier)
            print("Deleted \(summary.maskedDisplayName) [\(summary.accountID)]")
        case "export":
            let remaining = Array(arguments.dropFirst())
            let outputURL: URL?
            if let path = remaining.first {
                outputURL = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            } else {
                outputURL = nil
            }
            let result = try accountService.exportAccountsJSON(to: outputURL)
            print("Exported \(result.accountCount) accounts to \(result.fileURL.path)")
        case "import":
            let remaining = Array(arguments.dropFirst())
            guard let path = remaining.first else {
                throw CLIError("Missing import file path.")
            }
            let inputURL = URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
            let result = try accountService.importAccountsJSON(from: inputURL)
            print("Imported \(result.totalCount) account(s): +\(result.addedCount) new, \(result.updatedCount) updated")
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
            let email = account.maskedEmail ?? "-"
            let plan = account.effectivePlanType ?? "-"
            let team = account.teamName ?? "-"
            let usage = usageSummary(for: account)
            print("\(marker) \(account.id)  \(account.maskedDisplayName)  \(email)  \(account.accountID)  \(plan)  \(team)  \(usage)")
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
      export [OUTPUT_PATH]
      import INPUT_PATH

    Notes:
      - Accounts are read from Copool: ~/Library/Application Support/CodexToolsSwift/accounts.json
      - Current Codex auth is read from and written to ~/.codex/auth.json
      - switch also updates currentSelection in the Copool store
      - delete removes the saved account from the Copool store
      - export writes all saved account JSON for quick import (default: ~/Downloads/codex-accounts-export-*.json)
      - import reads an exported JSON file and merges accounts by account id
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
