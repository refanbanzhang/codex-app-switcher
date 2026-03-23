import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// 主窗口与 sheet 共用列宽，避免弹层比窗口更宽。
private enum CodexAppSwitcherLayout {
    static let columnWidth: CGFloat = 370
}

private enum AppLanguage: String {
    case chinese = "zh-Hans"
    case english = "en"

    static let storageKey = "ui.language"

    var next: AppLanguage {
        switch self {
        case .chinese:
            return .english
        case .english:
            return .chinese
        }
    }

    var toggleLabel: String {
        switch self {
        case .chinese:
            return "EN"
        case .english:
            return "中文"
        }
    }

    var localeIdentifier: String {
        rawValue
    }
}

private enum AppTheme: String {
    case light
    case dark

    static let storageKey = "ui.theme"

    var colorScheme: ColorScheme {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var next: AppTheme {
        switch self {
        case .light:
            return .dark
        case .dark:
            return .light
        }
    }
}

private struct AppCopy {
    let language: AppLanguage

    var emptyAccountsNotice: String {
        switch language {
        case .chinese:
            return "保存列表中还没有可切换的账号。"
        case .english:
            return "No switchable accounts in the saved list yet."
        }
    }

    func switchedTo(_ name: String) -> String {
        switch language {
        case .chinese:
            return "已切换到 \(name)，并启动 Codex。"
        case .english:
            return "Switched to \(name) and launched Codex."
        }
    }

    func addedAccount(_ name: String) -> String {
        switch language {
        case .chinese:
            return "已登录并添加账号 \(name)"
        case .english:
            return "Signed in and added account \(name)."
        }
    }

    func deletedAccount(_ name: String) -> String {
        switch language {
        case .chinese:
            return "已删除 \(name)"
        case .english:
            return "Deleted \(name)."
        }
    }

    func clearedAccounts(accountCount: Int, removedCurrentAuth: Bool) -> String {
        switch language {
        case .chinese:
            if removedCurrentAuth {
                return "已清空 \(accountCount) 个账号，包括当前账号登录状态"
            }
            return "已清空 \(accountCount) 个账号"
        case .english:
            if removedCurrentAuth {
                return "Cleared \(accountCount) account(s), including the current sign-in."
            }
            return "Cleared \(accountCount) account(s)."
        }
    }

    var deleteAccountTitle: String {
        switch language {
        case .chinese:
            return "删除这个账号？"
        case .english:
            return "Delete this account?"
        }
    }

    var clearAccountsTitle: String {
        switch language {
        case .chinese:
            return "清空全部账户（包括当前账号）？"
        case .english:
            return "Clear all accounts, including the current one?"
        }
    }

    var deleteAction: String {
        switch language {
        case .chinese:
            return "删除"
        case .english:
            return "Delete"
        }
    }

    var cancelAction: String {
        switch language {
        case .chinese:
            return "取消"
        case .english:
            return "Cancel"
        }
    }

    func deleteAccountMessage(accountName: String?) -> String {
        switch language {
        case .chinese:
            if let accountName {
                return "将从保存列表中移除 \(accountName)。当前账号不能删除。"
            }
            return "将从保存列表中移除此账号。"
        case .english:
            if let accountName {
                return "This removes \(accountName) from the saved list. The current account cannot be deleted."
            }
            return "This removes the account from the saved list."
        }
    }

    func clearAccountsMessage(accountCount: Int) -> String {
        switch language {
        case .chinese:
            return "这会移除保存列表中的 \(accountCount) 个账号，包括当前账号，并删除 ~/.codex/auth.json 登录状态。此操作不可撤销。"
        case .english:
            return "This removes \(accountCount) saved account(s), including the current one, and deletes the ~/.codex/auth.json sign-in state. This cannot be undone."
        }
    }

    var loadingAccounts: String {
        switch language {
        case .chinese:
            return "正在读取账号..."
        case .english:
            return "Loading accounts..."
        }
    }

    var addAccountAction: String {
        switch language {
        case .chinese:
            return "登录新账号"
        case .english:
            return "Add Account"
        }
    }

    var addAccountLoadingAction: String {
        switch language {
        case .chinese:
            return "登录中…"
        case .english:
            return "Signing In…"
        }
    }

    var exportAccountsAction: String {
        switch language {
        case .chinese:
            return "导出账号JSON"
        case .english:
            return "Export JSON"
        }
    }

    var clearAccountsAction: String {
        switch language {
        case .chinese:
            return "清空账户"
        case .english:
            return "Clear Accounts"
        }
    }

    var clearingAccountsAction: String {
        switch language {
        case .chinese:
            return "清空中…"
        case .english:
            return "Clearing…"
        }
    }

    var exportingAccountsAction: String {
        switch language {
        case .chinese:
            return "导出中…"
        case .english:
            return "Exporting…"
        }
    }

    var importAccountsAction: String {
        switch language {
        case .chinese:
            return "导入账号JSON"
        case .english:
            return "Import JSON"
        }
    }

    var importingAccountsAction: String {
        switch language {
        case .chinese:
            return "导入中…"
        case .english:
            return "Importing…"
        }
    }

    func exportedAccounts(accountCount: Int, outputPath: String) -> String {
        switch language {
        case .chinese:
            return "已导出 \(accountCount) 个账号到 \(outputPath)"
        case .english:
            return "Exported \(accountCount) account(s) to \(outputPath)"
        }
    }

    func importedAccounts(totalCount: Int, addedCount: Int, updatedCount: Int) -> String {
        switch language {
        case .chinese:
            return "已导入 \(totalCount) 个账号（新增 \(addedCount)，更新 \(updatedCount)）"
        case .english:
            return "Imported \(totalCount) account(s): +\(addedCount) new, \(updatedCount) updated"
        }
    }

    var currentPillTitle: String {
        switch language {
        case .chinese:
            return "当前账号"
        case .english:
            return "CURRENT"
        }
    }

    var switchAction: String {
        switch language {
        case .chinese:
            return "切换"
        case .english:
            return "SWITCH"
        }
    }

    var deleteAccountMenu: String {
        switch language {
        case .chinese:
            return "删除账号"
        case .english:
            return "Delete Account"
        }
    }

    var deletingAccountMenu: String {
        switch language {
        case .chinese:
            return "删除中…"
        case .english:
            return "Deleting…"
        }
    }

    var syncing: String {
        switch language {
        case .chinese:
            return "同步中"
        case .english:
            return "SYNCING"
        }
    }

    func remainingHeadline(_ remainingPercent: Double) -> String {
        let value = Int(remainingPercent.rounded())
        switch language {
        case .chinese:
            return "剩余 \(value)%"
        case .english:
            return "\(value)% Remaining"
        }
    }

    var noActiveUsage: String {
        switch language {
        case .chinese:
            return "暂无使用"
        case .english:
            return "No active usage"
        }
    }

    var fiveHourUsageSection: String {
        switch language {
        case .chinese:
            return "5 小时"
        case .english:
            return "5 Hours"
        }
    }

    var oneWeekUsageSection: String {
        switch language {
        case .chinese:
            return "1 周"
        case .english:
            return "1 Week"
        }
    }

    func resetsIn(days: Int) -> String {
        switch language {
        case .chinese:
            return "\(days) 天后重置"
        case .english:
            return "Resets in \(days) days"
        }
    }

    func resetsAt(_ dateText: String) -> String {
        switch language {
        case .chinese:
            return "\(dateText) 重置"
        case .english:
            return "Resets \(dateText)"
        }
    }

    var resetsToday: String {
        switch language {
        case .chinese:
            return "今天重置"
        case .english:
            return "Resets today"
        }
    }

    var emptyAccountsTitle: String {
        switch language {
        case .chinese:
            return "还没有可切换账号"
        case .english:
            return "No Switchable Accounts Yet"
        }
    }

    var emptyAccountsDescription: String {
        switch language {
        case .chinese:
            return "登录一个新账号后，这里会自动生成可切换卡片。"
        case .english:
            return "After you sign in with a new account, switchable cards will appear here automatically."
        }
    }

    var accountStorePathLabel: String {
        switch language {
        case .chinese:
            return "读取路径：~/Library/Application Support/codex-app-switcher/accounts.json"
        case .english:
            return "Store path: ~/Library/Application Support/codex-app-switcher/accounts.json"
        }
    }

    var authPathLabel: String {
        switch language {
        case .chinese:
            return "当前 auth 路径：~/.codex/auth.json"
        case .english:
            return "Current auth path: ~/.codex/auth.json"
        }
    }

    var languageButtonLabel: String {
        language.toggleLabel
    }

    func themeButtonLabel(for theme: AppTheme) -> String {
        switch (language, theme) {
        case (.chinese, .light):
            return "夜间"
        case (.chinese, .dark):
            return "日间"
        case (.english, .light):
            return "Dark"
        case (.english, .dark):
            return "Light"
        }
    }

    var settingsMenuLabel: String {
        switch language {
        case .chinese:
            return "设置"
        case .english:
            return "Settings"
        }
    }

    var refreshUsageAction: String {
        switch language {
        case .chinese:
            return "刷新"
        case .english:
            return "Refresh"
        }
    }

    var refreshingUsageAction: String {
        switch language {
        case .chinese:
            return "刷新中…"
        case .english:
            return "Refreshing…"
        }
    }
}

fileprivate enum AppNotice {
    case emptyAccounts
    case switched(String)
    case added(String)
    case deleted(String)
    case cleared(accountCount: Int, removedCurrentAuth: Bool)
    case exported(accountCount: Int, outputPath: String)
    case imported(totalCount: Int, addedCount: Int, updatedCount: Int)

    func localized(using copy: AppCopy) -> String {
        switch self {
        case .emptyAccounts:
            return copy.emptyAccountsNotice
        case .switched(let name):
            return copy.switchedTo(name)
        case .added(let name):
            return copy.addedAccount(name)
        case .deleted(let name):
            return copy.deletedAccount(name)
        case .cleared(let accountCount, let removedCurrentAuth):
            return copy.clearedAccounts(accountCount: accountCount, removedCurrentAuth: removedCurrentAuth)
        case .exported(let accountCount, let outputPath):
            return copy.exportedAccounts(accountCount: accountCount, outputPath: outputPath)
        case .imported(let totalCount, let addedCount, let updatedCount):
            return copy.importedAccounts(totalCount: totalCount, addedCount: addedCount, updatedCount: updatedCount)
        }
    }
}

@main
struct CodexAppSwitcherApp: App {
    @StateObject private var model = AccountSwitcherViewModel()
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.light.rawValue

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedTheme) ?? .light
    }

    var body: some Scene {
        WindowGroup("codex-app-switcher") {
            ContentView(model: model)
                .frame(minWidth: CodexAppSwitcherLayout.columnWidth, idealWidth: CodexAppSwitcherLayout.columnWidth, maxWidth: 410, minHeight: 760)
                .preferredColorScheme(selectedTheme.colorScheme)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AccountSwitcherViewModel: ObservableObject {
    @Published var accounts: [AccountSummary] = []
    @Published var isLoading = false
    @Published var isLoggingIn = false
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var isClearingAccounts = false
    @Published var switchingAccountID: String?
    @Published var deletingAccountID: String?
    @Published var pendingDeletionAccount: AccountSummary?
    @Published var pendingClearAllAccountCount: Int?
    @Published var errorMessage: String?
    @Published fileprivate var notice: AppNotice?
    @Published fileprivate private(set) var refreshingUsageAccountID: String?
    @Published fileprivate private(set) var isBulkUsageRefreshInFlight = false

    private let accountService: AccountService
    private let codexAppController = CodexAppController()
    private var bannerDismissTask: Task<Void, Never>?
    private var loadGeneration: UInt64 = 0

    var isUsageRefreshInFlight: Bool {
        refreshingUsageAccountID != nil || isBulkUsageRefreshInFlight
    }

    init() {
        do {
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
        } catch {
            self.accountService = AccountService(
                authRepository: AuthRepository(paths: AppPaths(
                    appSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    codexConfigPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                )),
                storeRepository: StoreRepository(paths: AppPaths(
                    appSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    codexConfigPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                )),
                loginService: OpenAIChatGPTOAuthLoginService(configPath: URL(fileURLWithPath: "/")),
                usageService: ChatGPTUsageService()
            )
            self.errorMessage = error.localizedDescription
            scheduleBannerDismissal()
        }
    }

    deinit {
        bannerDismissTask?.cancel()
    }

    func load(preserveNotice: Bool = false) async {
        loadGeneration &+= 1
        let generation = loadGeneration
        isLoading = true

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            let loadedAccounts = sortAccounts(try accountService.loadAccounts())
            guard generation == loadGeneration else { return }

            accounts = loadedAccounts
            if !preserveNotice {
                if accounts.isEmpty {
                    showNotice(.emptyAccounts)
                } else {
                    clearBanner()
                }
            }
            errorMessage = nil

            isLoading = false
            guard !loadedAccounts.isEmpty else { return }

            await refreshCurrentUsageIfNeeded(applyForGeneration: generation)
        } catch {
            guard generation == loadGeneration else { return }
            isLoading = false
            accounts = []
            showError(error.localizedDescription)
        }
    }

    private func refreshCurrentUsageIfNeeded(applyForGeneration generation: UInt64? = nil) async {
        guard let currentAccount = accounts.first(where: { $0.isCurrent }) else { return }
        await refreshUsageIfNeeded(for: currentAccount.id, applyForGeneration: generation, showErrorIfFailed: false)
    }

    private func refreshUsageIfNeeded(for accountIdentifier: String, applyForGeneration generation: UInt64? = nil, showErrorIfFailed: Bool = false) async {
        guard refreshingUsageAccountID == nil, !isBulkUsageRefreshInFlight else { return }

        refreshingUsageAccountID = accountIdentifier
        defer { refreshingUsageAccountID = nil }

        do {
            let refreshedAccounts = sortAccounts(try await accountService.refreshUsageForAccount(identifier: accountIdentifier))
            guard generation == nil || generation == loadGeneration else { return }
            accounts = refreshedAccounts
        } catch {
            if showErrorIfFailed {
                showError(error.localizedDescription)
            }
        }
    }

    func refreshUsageManually(for account: AccountSummary) async {
        guard !isLoading else { return }

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            await refreshUsageIfNeeded(for: account.id, applyForGeneration: loadGeneration, showErrorIfFailed: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func refreshAllUsageIfNeeded(applyForGeneration generation: UInt64? = nil, showErrorIfFailed: Bool = false) async {
        guard !isBulkUsageRefreshInFlight, refreshingUsageAccountID == nil else { return }

        isBulkUsageRefreshInFlight = true
        defer { isBulkUsageRefreshInFlight = false }

        do {
            let refreshedAccounts = sortAccounts(try await accountService.refreshUsageForAllAccounts())
            guard generation == nil || generation == loadGeneration else { return }
            accounts = refreshedAccounts
        } catch {
            if showErrorIfFailed {
                showError(error.localizedDescription)
            }
        }
    }

    func refreshUsageManually() async {
        guard !isLoading else { return }

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            await refreshAllUsageIfNeeded(applyForGeneration: loadGeneration, showErrorIfFailed: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func sortAccounts(_ accounts: [AccountSummary]) -> [AccountSummary] {
        accounts.sorted { lhs, rhs in
            let lhsHasUsage = lhs.fiveHourRemainingPercent != nil || lhs.oneWeekRemainingPercent != nil
            let rhsHasUsage = rhs.fiveHourRemainingPercent != nil || rhs.oneWeekRemainingPercent != nil
            if lhsHasUsage != rhsHasUsage {
                return lhsHasUsage && !rhsHasUsage
            }

            let lhsOneWeek = lhs.oneWeekRemainingPercent ?? -1
            let rhsOneWeek = rhs.oneWeekRemainingPercent ?? -1
            if lhsOneWeek != rhsOneWeek {
                return lhsOneWeek > rhsOneWeek
            }

            let lhsFiveHour = lhs.fiveHourRemainingPercent ?? -1
            let rhsFiveHour = rhs.fiveHourRemainingPercent ?? -1
            if lhsFiveHour != rhsFiveHour {
                return lhsFiveHour > rhsFiveHour
            }

            return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
        }
    }

    func switchAccount(_ account: AccountSummary) async {
        switchingAccountID = account.id
        defer { switchingAccountID = nil }

        do {
            let switched = try accountService.switchAccount(identifier: account.id)
            try await codexAppController.relaunchOrLaunch()
            showNotice(.switched(switched.maskedDisplayName))
            await load(preserveNotice: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func addAccountViaLogin() async {
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let imported = try await accountService.addAccountViaLogin()
            showNotice(.added(imported.maskedDisplayName))
            await load(preserveNotice: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func exportAccountsJSON() {
        isExporting = true
        defer { isExporting = false }

        do {
            let result = try accountService.exportAccountsJSON()
            showNotice(.exported(accountCount: result.accountCount, outputPath: result.fileURL.path))
        } catch {
            showError(error.localizedDescription)
        }
    }

    func importAccountsJSON(from fileURL: URL) async {
        isImporting = true
        defer { isImporting = false }

        do {
            let result = try accountService.importAccountsJSON(from: fileURL)
            showNotice(.imported(totalCount: result.totalCount, addedCount: result.addedCount, updatedCount: result.updatedCount))
            await load(preserveNotice: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func showImportPickerError(_ message: String) {
        showError(message)
    }

    func confirmDelete(_ account: AccountSummary) {
        pendingDeletionAccount = account
    }

    func cancelDelete() {
        pendingDeletionAccount = nil
    }

    func confirmClearAllAccounts() {
        let count = accounts.count
        guard count > 0 else { return }
        pendingClearAllAccountCount = count
    }

    func cancelClearAllAccounts() {
        pendingClearAllAccountCount = nil
    }

    func completeDeletion(of account: AccountSummary) async {
        pendingDeletionAccount = nil
        deletingAccountID = account.id
        defer { deletingAccountID = nil }

        do {
            let deleted = try accountService.deleteAccount(identifier: account.id)
            showNotice(.deleted(deleted.maskedDisplayName))
            await load(preserveNotice: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    func clearAllAccounts() async {
        pendingClearAllAccountCount = nil
        isClearingAccounts = true
        defer { isClearingAccounts = false }

        do {
            let result = try accountService.clearAllAccounts()
            showNotice(.cleared(accountCount: result.clearedAccountCount, removedCurrentAuth: result.removedCurrentAuth))
            await load(preserveNotice: true)
        } catch {
            showError(error.localizedDescription)
        }
    }

    private func showNotice(_ notice: AppNotice) {
        self.notice = notice
        errorMessage = nil
        scheduleBannerDismissal()
    }

    private func showError(_ message: String) {
        errorMessage = message
        notice = nil
        scheduleBannerDismissal()
    }

    private func clearBanner() {
        bannerDismissTask?.cancel()
        bannerDismissTask = nil
        notice = nil
        errorMessage = nil
    }

    private func scheduleBannerDismissal() {
        bannerDismissTask?.cancel()
        bannerDismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled else {
                return
            }
            await MainActor.run {
                self?.clearBanner()
            }
        }
    }

}

struct ContentView: View {
    @ObservedObject var model: AccountSwitcherViewModel
    @AppStorage(AppLanguage.storageKey) private var storedLanguage = AppLanguage.chinese.rawValue
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.light.rawValue
    @State private var isImporterPresented = false

    private var language: AppLanguage {
        AppLanguage(rawValue: storedLanguage) ?? .chinese
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedTheme) ?? .light
    }

    private var copy: AppCopy {
        AppCopy(language: language)
    }

    private var accountActionBusy: Bool {
        model.isLoggingIn
            || model.isLoading
            || model.isExporting
            || model.isImporting
            || model.isClearingAccounts
            || model.isUsageRefreshInFlight
            || model.switchingAccountID != nil
            || model.deletingAccountID != nil
    }

    var body: some View {
        ZStack {
            StudioBackground()

            WindowChromeConfigurator(theme: selectedTheme)
                .frame(width: 0, height: 0)

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    HStack(spacing: 8) {
                        FooterUtilityButton(
                            icon: "globe",
                            title: copy.languageButtonLabel,
                            tint: StudioTheme.ink,
                            action: { storedLanguage = language.next.rawValue }
                        )
                        FooterUtilityButton(
                            icon: selectedTheme == .light ? "moon.stars" : "sun.max",
                            title: copy.themeButtonLabel(for: selectedTheme),
                            tint: StudioTheme.ink,
                            action: { storedTheme = selectedTheme.next.rawValue }
                        )
                        FooterUtilityButton(
                            icon: "arrow.clockwise",
                            title: model.isUsageRefreshInFlight ? copy.refreshingUsageAction : copy.refreshUsageAction,
                            tint: StudioTheme.ink,
                            isDisabled: accountActionBusy || model.accounts.isEmpty,
                            action: {
                                Task {
                                    await model.refreshUsageManually()
                                }
                            }
                        )
                        utilitiesMenuButton
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    banner

                    if model.isLoading && model.accounts.isEmpty {
                        loadingBlock
                    } else if model.accounts.isEmpty {
                        EmptyAccountsCard(copy: copy)
                    } else {
                        ForEach(model.accounts) { account in
                            AccountCard(
                                account: account,
                                copy: copy,
                                isSwitching: model.switchingAccountID == account.id,
                                isDeleting: model.deletingAccountID == account.id,
                                isRefreshingUsage: model.refreshingUsageAccountID == account.id,
                                onRefreshUsage: {
                                    Task {
                                        await model.refreshUsageManually(for: account)
                                    }
                                },
                                onSwitch: {
                                    Task {
                                        await model.switchAccount(account)
                                    }
                                },
                                onDelete: {
                                    model.confirmDelete(account)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .overlay(alignment: .topLeading) {
                    ScrollViewOverlayConfigurator()
                        .frame(width: 0, height: 0)
                }
            }
        }
        .task {
            await model.load()
        }
        .alert(
            copy.deleteAccountTitle,
            isPresented: Binding(
                get: { model.pendingDeletionAccount != nil },
                set: { presented in
                    if !presented {
                        model.cancelDelete()
                    }
                }
            ),
            presenting: model.pendingDeletionAccount
        ) { account in
            Button(copy.deleteAction, role: .destructive) {
                Task {
                    await model.completeDeletion(of: account)
                }
            }
            Button(copy.cancelAction, role: .cancel) {
                model.cancelDelete()
            }
        } message: { account in
            Text(copy.deleteAccountMessage(accountName: account.maskedDisplayName))
        }
        .alert(
            copy.clearAccountsTitle,
            isPresented: Binding(
                get: { model.pendingClearAllAccountCount != nil },
                set: { presented in
                    if !presented {
                        model.cancelClearAllAccounts()
                    }
                }
            )
        ) {
            Button(copy.clearAccountsAction, role: .destructive) {
                Task {
                    await model.clearAllAccounts()
                }
            }
            Button(copy.cancelAction, role: .cancel) {
                model.cancelClearAllAccounts()
            }
        } message: {
            Text(copy.clearAccountsMessage(accountCount: model.pendingClearAllAccountCount ?? 0))
        }
        .fileImporter(isPresented: $isImporterPresented, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let fileURL):
                Task {
                    await model.importAccountsJSON(from: fileURL)
                }
            case .failure(let error):
                let nsError = error as NSError
                if nsError.code == NSUserCancelledError {
                    return
                }
                model.showImportPickerError(error.localizedDescription)
            }
        }
    }

    private var loadingBlock: some View {
        VStack(spacing: 14) {
            ProgressView(copy.loadingAccounts)
                .tint(StudioTheme.primary)
                .foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    @ViewBuilder
    private var banner: some View {
        if let message = model.errorMessage {
            StatusBanner(message: message, icon: "exclamationmark.triangle", tint: StudioTheme.danger)
        } else if let notice = model.notice {
            StatusBanner(message: notice.localized(using: copy), icon: "checkmark.circle", tint: StudioTheme.success)
        }
    }

    private var utilitiesMenuButton: some View {
        ToolbarSettingsMenuButton(
            model: model,
            isImporterPresented: $isImporterPresented,
            copy: copy,
            accountActionBusy: accountActionBusy
        )
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
    }
}

private struct WindowChromeConfigurator: NSViewRepresentable {
    let theme: AppTheme

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configureWindow(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindow(from: nsView)
        }
    }

    private func configureWindow(from view: NSView) {
        guard let window = view.window else {
            return
        }

        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.isMovableByWindowBackground = true
        window.backgroundColor = StudioTheme.windowChromeColor(for: theme)
        window.appearance = NSAppearance(named: theme == .dark ? .darkAqua : .aqua)
    }
}

private struct ToolbarSettingsMenuButton: NSViewRepresentable {
    @ObservedObject var model: AccountSwitcherViewModel
    @Binding var isImporterPresented: Bool
    let copy: AppCopy
    let accountActionBusy: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.parent = self
        let container = NSView()
        let hosting = NSHostingView(
            rootView: FooterUtilityCapsuleLabel(
                icon: "gearshape",
                title: copy.settingsMenuLabel,
                tint: StudioTheme.ink
            )
        )
        hosting.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hosting)

        let button = NSButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.bezelStyle = .shadowlessSquare
        button.isBordered = false
        button.title = ""
        button.setButtonType(.momentaryPushIn)
        button.focusRingType = .none
        button.target = context.coordinator
        button.action = #selector(Coordinator.showMenu(_:))
        button.sendAction(on: [.leftMouseUp])
        button.menu = context.coordinator.rebuildMenu()
        container.addSubview(button)

        context.coordinator.hostingView = hosting
        context.coordinator.button = button

        NSLayoutConstraint.activate([
            hosting.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hosting.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            hosting.topAnchor.constraint(equalTo: container.topAnchor),
            hosting.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            button.topAnchor.constraint(equalTo: container.topAnchor),
            button.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.hostingView?.rootView = FooterUtilityCapsuleLabel(
            icon: "gearshape",
            title: copy.settingsMenuLabel,
            tint: StudioTheme.ink
        )
        context.coordinator.button?.menu = context.coordinator.rebuildMenu()
        nsView.invalidateIntrinsicContentSize()
    }

    @MainActor
    final class Coordinator: NSObject {
        var parent: ToolbarSettingsMenuButton!
        weak var hostingView: NSHostingView<FooterUtilityCapsuleLabel>?
        weak var button: NSButton?

        func rebuildMenu() -> NSMenu {
            let menu = NSMenu()
            guard let parent else {
                return menu
            }

            let loginItem = NSMenuItem(
                title: parent.model.isLoggingIn ? parent.copy.addAccountLoadingAction : parent.copy.addAccountAction,
                action: #selector(login),
                keyEquivalent: ""
            )
            loginItem.target = self
            loginItem.image = NSImage(systemSymbolName: "person.badge.plus", accessibilityDescription: nil)
            loginItem.isEnabled = !parent.accountActionBusy
            menu.addItem(loginItem)

            let importItem = NSMenuItem(
                title: parent.model.isImporting ? parent.copy.importingAccountsAction : parent.copy.importAccountsAction,
                action: #selector(importJSON),
                keyEquivalent: ""
            )
            importItem.target = self
            importItem.image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil)
            importItem.isEnabled = !parent.accountActionBusy
            menu.addItem(importItem)

            let exportItem = NSMenuItem(
                title: parent.model.isExporting ? parent.copy.exportingAccountsAction : parent.copy.exportAccountsAction,
                action: #selector(exportJSON),
                keyEquivalent: ""
            )
            exportItem.target = self
            exportItem.image = NSImage(systemSymbolName: "square.and.arrow.up", accessibilityDescription: nil)
            exportItem.isEnabled = !parent.accountActionBusy
            menu.addItem(exportItem)

            menu.addItem(.separator())

            let clearItem = NSMenuItem(
                title: parent.model.isClearingAccounts ? parent.copy.clearingAccountsAction : parent.copy.clearAccountsAction,
                action: #selector(clearAccounts),
                keyEquivalent: ""
            )
            clearItem.target = self
            clearItem.image = NSImage(systemSymbolName: "trash.slash", accessibilityDescription: nil)
            clearItem.isEnabled = !parent.accountActionBusy && !parent.model.accounts.isEmpty
            menu.addItem(clearItem)

            return menu
        }

        @objc func login(_ sender: Any?) {
            Task { @MainActor in
                await self.parent.model.addAccountViaLogin()
            }
        }

        @objc func importJSON(_ sender: Any?) {
            Task { @MainActor in
                self.parent.isImporterPresented = true
            }
        }

        @objc func exportJSON(_ sender: Any?) {
            Task { @MainActor in
                self.parent.model.exportAccountsJSON()
            }
        }

        @objc func clearAccounts(_ sender: Any?) {
            Task { @MainActor in
                self.parent.model.confirmClearAllAccounts()
            }
        }

        @objc func showMenu(_ sender: NSButton) {
            guard let menu = sender.menu else { return }
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.bounds.height), in: sender)
        }
    }
}

private struct ScrollViewOverlayConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(from: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(from: nsView)
        }
    }

    private func configure(from view: NSView) {
        guard let scrollView = view.enclosingScrollView ?? enclosingScrollView(from: view) else {
            return
        }
        // overlay：滚动条叠在内容侧，不挤占内容区宽度（与 legacy 轨道相反）
        scrollView.scrollerStyle = .overlay
        scrollView.autohidesScrollers = true
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
    }

    private func enclosingScrollView(from view: NSView) -> NSScrollView? {
        var current: NSView? = view
        while let candidate = current {
            if let scrollView = candidate as? NSScrollView {
                return scrollView
            }
            current = candidate.superview
        }
        return nil
    }
}

/// 与 `effectivePlanType` 同步：标签与用量条共用同一套强调色；工作区团队名单独用 `workspaceTeam` 蓝色，避免与订阅档位「Team」混淆。
private enum AccountPlanKind {
    case free
    case plus
    case pro
    case team
    case enterprise
    case unknown

    static func resolve(_ raw: String?) -> AccountPlanKind {
        let s = raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        if s.isEmpty {
            return .unknown
        }

        if s.contains("enterprise") {
            return .enterprise
        }
        if s.contains("business") {
            return .team
        }
        if s.contains("team") {
            return .team
        }
        if s.contains("pro") {
            return .pro
        }
        if s.contains("plus") {
            return .plus
        }
        if s.contains("free") {
            return .free
        }
        if s.contains("trial") {
            return .plus
        }
        return .unknown
    }

    var chipStyle: StitchChip.Style {
        switch self {
        case .free:
            return .planFree
        case .plus:
            return .planPlus
        case .team:
            return .planTeam
        case .pro:
            return .neutral
        case .enterprise:
            return .neutral
        case .unknown:
            return .neutral
        }
    }
}

private struct AccountCard: View {
    let account: AccountSummary
    let copy: AppCopy
    let isSwitching: Bool
    let isDeleting: Bool
    let isRefreshingUsage: Bool
    let onRefreshUsage: () -> Void
    let onSwitch: () -> Void
    let onDelete: () -> Void
    @State private var revealsFullEmail = false
    @State private var isSwitchButtonHovered = false
    @State private var isCurrentPillHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(emailLine)
                        .font(StudioFont.label(11))
                        .foregroundStyle(StudioTheme.ink)
                        .fontWeight(account.isCurrent ? .bold : .semibold)
                        .tracking(0.6)
                        .lineLimit(1)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 2) {
                            revealsFullEmail.toggle()
                        }

                    HStack(spacing: 8) {
                        if let planType = account.effectivePlanType, !planType.isEmpty {
                            StitchChip(
                                text: planType.uppercased(),
                                style: AccountPlanKind.resolve(planType).chipStyle
                            )
                        }

                        if let teamName = account.teamName, !teamName.isEmpty {
                            StitchChip(text: teamName.uppercased(), style: .neutral)
                        }
                    }
                }
                .frame(minWidth: 0, alignment: .leading)

                Spacer(minLength: 8)

                HStack(spacing: 4) {
                    Button {
                        onRefreshUsage()
                    } label: {
                        if isRefreshingUsage {
                            ProgressView()
                                .controlSize(.small)
                                .tint(StudioTheme.ink)
                                .frame(width: 14, height: 14)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11, weight: .semibold))
                                .frame(width: 14, height: 14)
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(StudioTheme.ink)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(StudioTheme.surfaceContainer)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(StudioTheme.outlineVariant.opacity(0.12), lineWidth: 1)
                    )
                    .disabled(isSwitching || isDeleting || isRefreshingUsage)
                    .help(isRefreshingUsage ? copy.refreshingUsageAction : copy.refreshUsageAction)

                    if account.isCurrent {
                        currentContextPill
                    } else {
                        Button {
                            onSwitch()
                        } label: {
                            HStack(spacing: 6) {
                                if isSwitching {
                                    ProgressView()
                                        .controlSize(.small)
                                        .tint(StudioTheme.ink)
                                } else {
                                    Image(systemName: "arrow.left.arrow.right")
                                        .font(.system(size: 11, weight: .semibold))
                                }

                                if isSwitchButtonHovered {
                                    Text(copy.switchAction)
                                        .font(StudioFont.label(10))
                                        .lineLimit(1)
                                        .fixedSize(horizontal: true, vertical: false)
                                        .transition(.move(edge: .trailing).combined(with: .opacity))
                                }
                            }
                            .foregroundStyle(StudioTheme.ink)
                            .padding(.horizontal, isSwitchButtonHovered ? 12 : 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(StudioTheme.surfaceContainer)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(StudioTheme.outlineVariant.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isSwitching || isDeleting || isRefreshingUsage)
                        .onHover { hovering in
                            isSwitchButtonHovered = hovering && !isSwitching && !isDeleting && !isRefreshingUsage
                        }
                        .help(copy.switchAction)
                        .animation(.easeOut(duration: 0.16), value: isSwitchButtonHovered)
                    }
                }
            }

            StitchUsageStrip(account: account, copy: copy)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassPanelBackground(
                cornerRadius: 16,
                fillOpacity: 0.7,
                borderColor: StudioTheme.outlineVariant.opacity(0.1),
                shadowRadius: 6
            )
        }
        .overlay {
            if account.isCurrent {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(StudioTheme.currentAccountBorder, lineWidth: 1.5)
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(isDeleting ? copy.deletingAccountMenu : copy.deleteAccountMenu, systemImage: "trash")
            }
            .disabled(isSwitching || isDeleting || isRefreshingUsage || account.isCurrent)
        }
    }

    private var emailLine: String {
        let value: String
        if revealsFullEmail {
            value = account.email ?? account.displayName
        } else {
            value = account.maskedEmail ?? account.maskedDisplayName
        }
        return value.uppercased()
    }

    private var currentContextPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(StudioTheme.ink)

            if isCurrentPillHovered {
                Text(currentPillTitle)
                    .font(StudioFont.label(10))
                    .foregroundStyle(StudioTheme.ink)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(StudioTheme.currentAccountBorder.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(StudioTheme.currentAccountBorder.opacity(0.55), lineWidth: 1)
        )
        .onHover { hovering in
            isCurrentPillHovered = hovering
        }
        .help(currentPillTitle)
        .animation(.easeOut(duration: 0.16), value: isCurrentPillHovered)
    }

    private var currentPillTitle: String {
        copy.currentPillTitle
    }
}

private struct StitchUsageStrip: View {
    let account: AccountSummary
    let copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if snapshots.isEmpty {
                UsageMeterRow(
                    copy: copy,
                    section: .fiveHour,
                    remainingHeadline: copy.syncing,
                    remainingHeadlineTint: StudioTheme.accentFree,
                    barFill: StudioTheme.accentFree.opacity(0.35),
                    barGlow: .clear,
                    progress: 0,
                    resetCaption: "—"
                )
            } else {
                ForEach(Array(snapshots.enumerated()), id: \.element.id) { index, snapshot in
                    if index > 0 {
                        Rectangle()
                            .fill(StudioTheme.outlineVariant.opacity(0.05))
                            .frame(height: 1)
                            .padding(.bottom, 16)
                    }
                    UsageMeterRow(
                        copy: copy,
                        section: snapshot.section,
                        remainingHeadline: snapshot.remainingHeadline,
                        remainingHeadlineTint: snapshot.remainingHeadlineTint,
                        barFill: snapshot.barFill,
                        barGlow: snapshot.barGlow,
                        progress: snapshot.progress,
                        resetCaption: snapshot.resetCaption
                    )
                }
            }
        }
        .padding(.top, 4)
    }

    private var snapshots: [UsageSnapshot] {
        var values: [UsageSnapshot] = []
        if let fiveHour = account.usage?.fiveHour {
            values.append(makeSnapshot(section: .fiveHour, windowKind: .fiveHour, window: fiveHour))
        }
        if let oneWeek = account.usage?.oneWeek {
            values.append(makeSnapshot(section: .oneWeek, windowKind: .oneWeek, window: oneWeek))
        }
        return values
    }

    private enum WindowKind {
        case oneWeek
        case fiveHour
    }

    private func makeSnapshot(section: UsageMeterRow.Section, windowKind: WindowKind, window: UsageWindow) -> UsageSnapshot {
        let remaining = window.remainingPercent
        let remainingHeadline = remaining.map(copy.remainingHeadline(_:)) ?? copy.syncing
        let remainingHeadlineTint: Color = {
            guard remaining != nil else {
                return StudioTheme.accentFree
            }
            return StudioTheme.accentFree
        }()
        let barFill: Color = {
            if remaining == nil {
                return StudioTheme.accentFree.opacity(0.35)
            }
            return StudioTheme.accentFree
        }()
        let barGlow: Color = {
            guard let remaining, remaining < 99.5 else {
                return .clear
            }
            return StudioTheme.accentFree.opacity(0.24)
        }()
        let progress = max(0, min(remaining ?? 0, 100)) / 100
        let resetCaption: String = {
            if let used = window.usedPercent, used <= 0.01 {
                if section == .fiveHour, let remaining, remaining >= 99.5 {
                    return ""
                }
                return copy.noActiveUsage
            }
            if let resetAt = window.resetAt {
                if section == .fiveHour {
                    return absoluteResetCaption(resetAt: resetAt, language: copy.language, copy: copy)
                }
                return relativeResetCaption(resetAt: resetAt, language: copy.language, copy: copy)
            }
            return "—"
        }()

        return UsageSnapshot(
            id: windowKind == .oneWeek ? "oneWeek" : "fiveHour",
            section: section,
            remainingHeadline: remainingHeadline,
            remainingHeadlineTint: remainingHeadlineTint,
            barFill: barFill,
            barGlow: barGlow,
            progress: progress,
            resetCaption: resetCaption
        )
    }

    private struct UsageSnapshot: Identifiable {
        let id: String
        let section: UsageMeterRow.Section
        let remainingHeadline: String
        let remainingHeadlineTint: Color
        let barFill: Color
        let barGlow: Color
        let progress: Double
        let resetCaption: String
    }
}

private struct UsageMeterRow: View {
    enum Section {
        case fiveHour
        case oneWeek
    }

    let copy: AppCopy
    let section: Section
    let remainingHeadline: String
    let remainingHeadlineTint: Color
    let barFill: Color
    let barGlow: Color
    let progress: Double
    let resetCaption: String

    private var sectionTitle: String {
        switch section {
        case .fiveHour:
            return copy.fiveHourUsageSection
        case .oneWeek:
            return copy.oneWeekUsageSection
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(sectionTitle)
                    .font(StudioFont.label(11))
                    .foregroundStyle(StudioTheme.accentFree)

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(remainingHeadline)
                        .font(StudioFont.label(11))
                        .foregroundStyle(remainingHeadlineTint)

                    if !resetCaption.isEmpty {
                        Text(resetCaption)
                            .font(StudioFont.caption(10))
                            .foregroundStyle(StudioTheme.accentFree)
                    }
                }
                .multilineTextAlignment(.trailing)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(StudioTheme.surfaceContainer)

                    Capsule()
                        .fill(barFill)
                        .frame(width: max(0, proxy.size.width * progress))
                        .shadow(color: barGlow, radius: 4, x: 0, y: 0)
                }
            }
            .frame(height: 6)
        }
    }
}

private func relativeResetCaption(resetAt: Int64, language: AppLanguage, copy: AppCopy) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(resetAt))
    let calendar = Calendar.current
    let startNow = calendar.startOfDay(for: Date())
    let startTarget = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: startNow, to: startTarget).day ?? 0
    if days > 0 {
        return copy.resetsIn(days: days)
    }
    if days < 0 {
        return copy.resetsAt(usageDateFormatter(for: language).string(from: date))
    }
    return copy.resetsToday
}

private func absoluteResetCaption(resetAt: Int64, language: AppLanguage, copy: AppCopy) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(resetAt))
    return copy.resetsAt(usageTimeFormatter(for: language).string(from: date))
}

private enum StudioFont {
    static func label(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

private struct StitchChip: View {
    enum Style {
        case current
        /// 工作区 / 团队名（蓝），与订阅档位「Team」区分
        case workspaceTeam
        case planFree
        case planPlus
        case planPro
        case planTeam
        case planEnterprise
        case neutral
    }

    let text: String
    let style: Style

    var body: some View {
        Text(text)
            .font(StudioFont.label(10))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(background, in: Capsule())
            .foregroundStyle(foreground)
    }

    private var background: Color {
        switch style {
        case .current:
            return StudioTheme.secondaryContainer
        case .workspaceTeam:
            return StudioTheme.workspaceTeamBackground
        case .planFree:
            return StudioTheme.planFreeBackground
        case .planPlus:
            return StudioTheme.planPlusBackground
        case .planPro:
            return StudioTheme.tertiaryContainer
        case .planTeam:
            return StudioTheme.planTeamBackground
        case .planEnterprise:
            return StudioTheme.planEnterpriseBackground
        case .neutral:
            return StudioTheme.secondaryContainer
        }
    }

    private var foreground: Color {
        switch style {
        case .current:
            return StudioTheme.onSecondaryContainer
        case .workspaceTeam:
            return StudioTheme.workspaceTeamForeground
        case .planFree:
            return StudioTheme.planFreeForeground
        case .planPlus:
            return StudioTheme.planPlusForeground
        case .planPro:
            return StudioTheme.onTertiaryContainer
        case .planTeam:
            return StudioTheme.planTeamForeground
        case .planEnterprise:
            return StudioTheme.planEnterpriseForeground
        case .neutral:
            return StudioTheme.onSecondaryContainer
        }
    }
}

private struct StatusBanner: View {
    let message: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))

            Text(message)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(tint)
        .padding(15)
        .background {
            GlassPanelBackground(cornerRadius: 20, fillOpacity: 0.78, borderColor: tint.opacity(0.16))
        }
    }
}

private struct EmptyAccountsCard: View {
    let copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(copy.emptyAccountsTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.ink)

            Text(copy.emptyAccountsDescription)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(StudioTheme.muted)

            VStack(alignment: .leading, spacing: 6) {
                Text(copy.accountStorePathLabel)
                Text(copy.authPathLabel)
            }
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(StudioTheme.secondary)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
        .padding(22)
        .background {
            GlassPanelBackground(cornerRadius: 24, fillOpacity: 0.74)
        }
    }
}

private struct GlassPanelBackground: View {
    let cornerRadius: CGFloat
    var fillOpacity: CGFloat = 0.8
    var borderColor: Color = StudioTheme.ghostBorder
    var shadowRadius: CGFloat = 24

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(StudioTheme.panelFill.opacity(fillOpacity))
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: StudioTheme.shadow, radius: shadowRadius, x: 0, y: shadowRadius > 12 ? 14 : 4)
    }
}

private struct FooterUtilityCapsuleLabel: View {
    let icon: String
    let title: String
    let tint: Color
    var isDisabled: Bool = false
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: isHovered ? 6 : 0) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))

            if isHovered {
                Text(title)
                    .font(StudioFont.label(10))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .foregroundStyle(isDisabled ? tint.opacity(0.45) : tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(StudioTheme.surfaceContainer.opacity(0.9))
        )
        .overlay(
            Capsule()
                .stroke(StudioTheme.outlineVariant.opacity(isDisabled ? 0.08 : 0.14), lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering && !isDisabled
        }
        .help(title)
        .animation(.easeOut(duration: 0.16), value: isHovered)
    }
}

private struct FooterUtilityButton: View {
    let icon: String
    let title: String
    let tint: Color
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FooterUtilityCapsuleLabel(icon: icon, title: title, tint: tint, isDisabled: isDisabled)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .fixedSize(horizontal: true, vertical: false)
        .layoutPriority(1)
    }
}

private struct StudioBackground: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    StudioTheme.canvasTop,
                    StudioTheme.surfaceContainer
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 520
            )

            Circle()
                .fill(StudioTheme.tertiaryContainer.opacity(0.2))
                .frame(width: 256, height: 256)
                .blur(radius: 100)
                .offset(x: -140, y: -180)

            Circle()
                .fill(StudioTheme.primaryContainer.opacity(0.1))
                .frame(width: 384, height: 384)
                .blur(radius: 120)
                .offset(x: 160, y: 280)
        }
        .ignoresSafeArea()
    }
}

private enum StudioTheme {
    static let canvasTop = adaptive(light: .rgba(0.984, 0.973, 0.988), dark: .rgba(0.090, 0.102, 0.129))
    static let primary = adaptive(light: .rgba(0.0, 0.478, 1.0), dark: .rgba(0.431, 0.694, 1.0))
    static let primaryContainer = adaptive(light: .rgba(0.188, 0.533, 0.965), dark: .rgba(0.169, 0.361, 0.627))
    static let secondary = adaptive(light: .rgba(0.349, 0.373, 0.431), dark: .rgba(0.702, 0.729, 0.780))
    static let secondaryContainer = adaptive(light: .rgba(0.867, 0.886, 0.957), dark: .rgba(0.176, 0.204, 0.286))
    static let onSecondaryContainer = adaptive(light: .rgba(0.298, 0.322, 0.376), dark: .rgba(0.851, 0.878, 0.941))
    static let tertiary = adaptive(light: .rgba(0.482, 0.322, 0.431), dark: .rgba(0.949, 0.690, 0.820))
    static let tertiaryContainer = adaptive(light: .rgba(0.980, 0.773, 0.902), dark: .rgba(0.286, 0.184, 0.255))
    static let onTertiaryContainer = adaptive(light: .rgba(0.388, 0.239, 0.345), dark: .rgba(0.988, 0.816, 0.922))
    static let surfaceContainer = adaptive(light: .rgba(0.933, 0.929, 0.953), dark: .rgba(0.133, 0.149, 0.184))
    static let outlineVariant = adaptive(light: .rgba(0.694, 0.694, 0.725), dark: .rgba(0.365, 0.396, 0.463))
    static let success = adaptive(light: .rgba(0.164, 0.498, 0.334), dark: .rgba(0.482, 0.839, 0.663))
    static let danger = adaptive(light: .rgba(0.749, 0.282, 0.341), dark: .rgba(0.980, 0.529, 0.573))
    static let ink = adaptive(light: .rgba(0.188, 0.196, 0.220), dark: .rgba(0.933, 0.945, 0.976))
    static let muted = adaptive(light: .rgba(0.365, 0.373, 0.396), dark: .rgba(0.627, 0.651, 0.706))
    static let ghostBorder = adaptive(light: .rgba(0.694, 0.694, 0.725, 0.18), dark: .rgba(0.627, 0.651, 0.706, 0.16))
    static let shadow = adaptive(light: .rgba(0.188, 0.196, 0.220, 0.06), dark: .rgba(0.0, 0.0, 0.0, 0.24))
    static let footerFill = adaptive(light: .rgba(0.976, 0.980, 0.984, 0.82), dark: .rgba(0.090, 0.102, 0.129, 0.88))
    static let footerMuted = adaptive(light: .rgba(0.608, 0.627, 0.651), dark: .rgba(0.757, 0.780, 0.827))
    static let footerTopBorder = adaptive(light: .rgba(0.88, 0.89, 0.92, 0.35), dark: .rgba(0.267, 0.294, 0.361, 0.55))
    static let footerShadow = adaptive(light: .rgba(0.0, 0.0, 0.0, 0.05), dark: .rgba(0.0, 0.0, 0.0, 0.34))
    static let panelFill = adaptive(light: .rgba(1.0, 1.0, 1.0), dark: .rgba(0.082, 0.090, 0.118))
    static let currentAccountBorder = adaptive(light: .rgba(0.48, 0.50, 0.55, 0.72), dark: .rgba(0.68, 0.71, 0.76, 0.72))

    /// 非当前账号用量条：与 plan 标签同色相，便于一眼对应档位
    static let accentFree = adaptive(light: .rgba(0.48, 0.50, 0.55), dark: .rgba(0.68, 0.71, 0.76))
    static let accentPlus = adaptive(light: .rgba(0.0, 0.50, 0.42), dark: .rgba(0.48, 0.93, 0.82))
    static let accentTeamPlan = adaptive(light: .rgba(0.14, 0.22, 0.68), dark: .rgba(0.62, 0.70, 1.0))
    static let accentEnterprise = adaptive(light: .rgba(0.62, 0.42, 0.12), dark: .rgba(0.925, 0.733, 0.451))
    static let workspaceTeamBackground = adaptive(light: .rgba(0.89, 0.95, 1.0), dark: .rgba(0.137, 0.235, 0.365))
    static let workspaceTeamForeground = adaptive(light: .rgba(0.15, 0.39, 0.92), dark: .rgba(0.612, 0.796, 1.0))
    /// Free：中性灰，避免与 Plus 青绿、Team 靛蓝混成「一片浅蓝」
    static let planFreeBackground = adaptive(light: .rgba(0.92, 0.93, 0.94), dark: .rgba(0.16, 0.17, 0.20))
    static let planFreeForeground = adaptive(light: .rgba(0.36, 0.38, 0.42), dark: .rgba(0.74, 0.77, 0.82))
    /// Plus：偏青绿轴，与 Team 的蓝色轴拉开
    static let planPlusBackground = adaptive(light: .rgba(0.78, 0.96, 0.90), dark: .rgba(0.08, 0.24, 0.22))
    static let planPlusForeground = adaptive(light: .rgba(0.0, 0.50, 0.42), dark: .rgba(0.48, 0.93, 0.82))
    /// Team：偏靛蓝 / 紫蓝，与 Plus 的青绿明显不同
    static let planTeamBackground = adaptive(light: .rgba(0.84, 0.87, 1.0), dark: .rgba(0.14, 0.16, 0.38))
    static let planTeamForeground = adaptive(light: .rgba(0.14, 0.22, 0.68), dark: .rgba(0.62, 0.70, 1.0))
    static let planEnterpriseBackground = adaptive(light: .rgba(1.0, 0.95, 0.88), dark: .rgba(0.322, 0.227, 0.102))
    static let planEnterpriseForeground = adaptive(light: .rgba(0.45, 0.30, 0.08), dark: .rgba(1.0, 0.859, 0.624))

    private struct RGBA {
        let red: CGFloat
        let green: CGFloat
        let blue: CGFloat
        let opacity: CGFloat

        static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ opacity: CGFloat = 1.0) -> RGBA {
            RGBA(red: red, green: green, blue: blue, opacity: opacity)
        }
    }

    private static func adaptive(light: RGBA, dark: RGBA) -> Color {
        Color(
            nsColor: NSColor(
                name: nil,
                dynamicProvider: { appearance in
                    let useDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                    let tone = useDark ? dark : light
                    return NSColor(
                        calibratedRed: tone.red,
                        green: tone.green,
                        blue: tone.blue,
                        alpha: tone.opacity
                    )
                }
            )
        )
    }

    static func windowChromeColor(for theme: AppTheme) -> NSColor {
        switch theme {
        case .light:
            return NSColor(calibratedRed: 0.984, green: 0.973, blue: 0.988, alpha: 1.0)
        case .dark:
            return NSColor(calibratedRed: 0.090, green: 0.102, blue: 0.129, alpha: 1.0)
        }
    }
}

private func usageDateFormatter(for language: AppLanguage) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: language.localeIdentifier)
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter
}

private func usageTimeFormatter(for language: AppLanguage) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: language.localeIdentifier)
    formatter.dateFormat = "HH:mm"
    return formatter
}

#if ENABLE_PREVIEWS
#Preview("codex-app-switcher") {
    ContentView(model: AccountSwitcherViewModel())
        .frame(width: CodexAppSwitcherLayout.columnWidth, height: 760)
}
#endif
