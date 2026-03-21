import AppKit
import SwiftUI

/// 主窗口与 sheet 共用列宽，避免弹层比窗口更宽。
private enum CodexSwitcherLayout {
    static let columnWidth: CGFloat = 390
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
            return "Copool 里还没有可切换的账号。"
        case .english:
            return "No switchable accounts were found in Copool yet."
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

    var deleteAccountTitle: String {
        switch language {
        case .chinese:
            return "删除这个账号？"
        case .english:
            return "Delete this account?"
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
                return "将从 Copool 保存列表中移除 \(accountName)。当前账号不能删除。"
            }
            return "将从 Copool 保存列表中移除此账号。"
        case .english:
            if let accountName {
                return "This removes \(accountName) from the Copool saved list. The current account cannot be deleted."
            }
            return "This removes the account from the Copool saved list."
        }
    }

    var loadingAccounts: String {
        switch language {
        case .chinese:
            return "正在读取账号并刷新用量..."
        case .english:
            return "Loading accounts and refreshing usage..."
        }
    }

    var addAccountAction: String {
        switch language {
        case .chinese:
            return "登录新增账号"
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

    var reloadAction: String {
        switch language {
        case .chinese:
            return "重新加载"
        case .english:
            return "Reload"
        }
    }

    var currentBadge: String {
        switch language {
        case .chinese:
            return "当前"
        case .english:
            return "CURRENT"
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

    var oneWeekWindow: String {
        switch language {
        case .chinese:
            return "1 周窗口"
        case .english:
            return "1 week window"
        }
    }

    var fiveHourWindow: String {
        switch language {
        case .chinese:
            return "5 小时窗口"
        case .english:
            return "5 hour window"
        }
    }

    var primaryUsageSection: String {
        switch language {
        case .chinese:
            return "资源用量"
        case .english:
            return "Resources Usage"
        }
    }

    var secondaryUsageSection: String {
        switch language {
        case .chinese:
            return "次级窗口用量"
        case .english:
            return "Usage (secondary)"
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
            return "读取路径：~/Library/Application Support/CodexToolsSwift/accounts.json"
        case .english:
            return "Store path: ~/Library/Application Support/CodexToolsSwift/accounts.json"
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
}

fileprivate enum AppNotice {
    case emptyAccounts
    case switched(String)
    case added(String)
    case deleted(String)

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
        }
    }
}

@main
struct CodexSwitcherApp: App {
    @StateObject private var model = AccountSwitcherViewModel()
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.light.rawValue

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedTheme) ?? .light
    }

    var body: some Scene {
        WindowGroup("Codex Switcher") {
            ContentView(model: model)
                .frame(minWidth: CodexSwitcherLayout.columnWidth, idealWidth: CodexSwitcherLayout.columnWidth, maxWidth: 430, minHeight: 760)
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
    @Published var switchingAccountID: String?
    @Published var deletingAccountID: String?
    @Published var pendingDeletionAccount: AccountSummary?
    @Published var errorMessage: String?
    @Published fileprivate var notice: AppNotice?

    private let accountService: AccountService
    private let codexAppController = CodexAppController()

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
                    copoolAppSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    codexConfigPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                )),
                storeRepository: StoreRepository(paths: AppPaths(
                    copoolAppSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    codexConfigPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                )),
                loginService: OpenAIChatGPTOAuthLoginService(configPath: URL(fileURLWithPath: "/")),
                usageService: ChatGPTUsageService()
            )
            self.errorMessage = error.localizedDescription
        }
    }

    func load(preserveNotice: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            accounts = try await accountService.refreshUsageForAllAccounts()
            if !preserveNotice {
                if accounts.isEmpty {
                    notice = .emptyAccounts
                } else {
                    notice = nil
                }
            }
            errorMessage = nil
        } catch {
            accounts = []
            errorMessage = error.localizedDescription
        }
    }

    func switchAccount(_ account: AccountSummary) async {
        switchingAccountID = account.id
        defer { switchingAccountID = nil }

        do {
            let switched = try accountService.switchAccount(identifier: account.id)
            try await codexAppController.relaunchOrLaunch()
            notice = .switched(switched.displayName)
            errorMessage = nil
            await load(preserveNotice: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addAccountViaLogin() async {
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let imported = try await accountService.addAccountViaLogin()
            notice = .added(imported.displayName)
            errorMessage = nil
            await load(preserveNotice: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func confirmDelete(_ account: AccountSummary) {
        pendingDeletionAccount = account
    }

    func cancelDelete() {
        pendingDeletionAccount = nil
    }

    func deletePendingAccount() async {
        guard let account = pendingDeletionAccount else {
            return
        }

        pendingDeletionAccount = nil
        deletingAccountID = account.id
        defer { deletingAccountID = nil }

        do {
            let deleted = try accountService.deleteAccount(identifier: account.id)
            notice = .deleted(deleted.displayName)
            errorMessage = nil
            await load(preserveNotice: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: AccountSwitcherViewModel
    @AppStorage(AppLanguage.storageKey) private var storedLanguage = AppLanguage.chinese.rawValue
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.light.rawValue

    private var language: AppLanguage {
        AppLanguage(rawValue: storedLanguage) ?? .chinese
    }

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: storedTheme) ?? .light
    }

    private var copy: AppCopy {
        AppCopy(language: language)
    }

    var body: some View {
        ZStack {
            StudioBackground()

            ScrollView {
                LazyVStack(spacing: 16) {
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
                .padding(.top, 24)
                .padding(.bottom, 96)
            }
            .scrollIndicators(.hidden)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                stitchFooterBar
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .task {
            await model.load()
        }
        .alert(
            copy.deleteAccountTitle,
            isPresented: Binding(
                get: { model.pendingDeletionAccount != nil },
                set: { isPresented in
                    if !isPresented {
                        model.cancelDelete()
                    }
                }
            )
        ) {
            Button(copy.deleteAction, role: .destructive) {
                Task {
                    await model.deletePendingAccount()
                }
            }
            Button(copy.cancelAction, role: .cancel) {
                model.cancelDelete()
            }
        } message: {
            Text(copy.deleteAccountMessage(accountName: model.pendingDeletionAccount?.displayName))
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
            StatusBanner(message: message, icon: "exclamationmark.triangle.fill", tint: StudioTheme.danger)
        } else if let notice = model.notice {
            StatusBanner(message: notice.localized(using: copy), icon: "checkmark.circle.fill", tint: StudioTheme.success)
        }
    }

    private var stitchFooterBar: some View {
        HStack {
            Button {
                Task {
                    await model.addAccountViaLogin()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 18, weight: .regular))
                    Text(model.isLoggingIn ? copy.addAccountLoadingAction : copy.addAccountAction)
                        .font(StudioFont.label(12))
                }
                .foregroundStyle(StudioTheme.primary)
            }
            .buttonStyle(.plain)
            .disabled(model.isLoggingIn || model.isLoading || model.switchingAccountID != nil || model.deletingAccountID != nil)

            Spacer(minLength: 12)

            HStack(spacing: 10) {
                FooterUtilityButton(
                    icon: "globe",
                    title: copy.languageButtonLabel,
                    tint: StudioTheme.footerMuted
                ) {
                    storedLanguage = language.next.rawValue
                }

                FooterUtilityButton(
                    icon: selectedTheme == .light ? "moon.stars.fill" : "sun.max.fill",
                    title: copy.themeButtonLabel(for: selectedTheme),
                    tint: StudioTheme.footerMuted
                ) {
                    storedTheme = selectedTheme.next.rawValue
                }
            }

            Button {
                Task {
                    await model.load()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .regular))
                    Text(copy.reloadAction)
                        .font(StudioFont.label(12))
                }
                .foregroundStyle(StudioTheme.footerMuted)
            }
            .buttonStyle(.plain)
            .disabled(model.isLoggingIn || model.deletingAccountID != nil)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(maxWidth: 430)
        .frame(maxWidth: .infinity)
        .background {
            ZStack(alignment: .top) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                StudioTheme.footerFill
            }
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(StudioTheme.footerTopBorder)
                    .frame(height: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(
            UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: 16,
                    bottomLeading: 0,
                    bottomTrailing: 0,
                    topTrailing: 16
                ),
                style: .continuous
            )
        )
        .shadow(color: StudioTheme.footerShadow, radius: 20, x: 0, y: -4)
        .ignoresSafeArea(edges: .bottom)
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
        case .pro:
            return .planPro
        case .team:
            return .planTeam
        case .enterprise:
            return .planEnterprise
        case .unknown:
            return .neutral
        }
    }

    var usageAccent: Color {
        switch self {
        case .free:
            return StudioTheme.accentFree
        case .plus:
            return StudioTheme.accentPlus
        case .pro:
            return StudioTheme.tertiary
        case .team:
            return StudioTheme.accentTeamPlan
        case .enterprise:
            return StudioTheme.accentEnterprise
        case .unknown:
            return StudioTheme.primary
        }
    }
}

private struct AccountCard: View {
    let account: AccountSummary
    let copy: AppCopy
    let isSwitching: Bool
    let isDeleting: Bool
    let onSwitch: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(emailLine)
                        .font(StudioFont.label(11))
                        .foregroundStyle(account.isCurrent ? StudioTheme.primary : StudioTheme.ink)
                        .fontWeight(account.isCurrent ? .bold : .semibold)
                        .tracking(0.6)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if account.isCurrent {
                            StitchChip(text: copy.currentBadge, style: .current)
                        }

                        if let planType = account.effectivePlanType, !planType.isEmpty {
                            StitchChip(
                                text: planType.uppercased(),
                                style: AccountPlanKind.resolve(planType).chipStyle
                            )
                        }

                        if let teamName = account.teamName, !teamName.isEmpty {
                            StitchChip(text: teamName.uppercased(), style: .workspaceTeam)
                        }
                    }
                }
                .frame(minWidth: 0, alignment: .leading)

                Spacer(minLength: 8)

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
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Text(copy.switchAction)
                                .font(StudioFont.label(10))
                        }
                        .foregroundStyle(StudioTheme.ink)
                        .padding(.horizontal, 12)
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
                    .disabled(isSwitching || isDeleting)
                }
            }

            StitchUsageStrip(account: account, accent: usageAccent, copy: copy)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            GlassPanelBackground(
                cornerRadius: 16,
                fillOpacity: 0.7,
                borderColor: account.isCurrent ? StudioTheme.primary.opacity(0.2) : StudioTheme.outlineVariant.opacity(0.1),
                shadowRadius: 6
            )
        }
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label(isDeleting ? copy.deletingAccountMenu : copy.deleteAccountMenu, systemImage: "trash")
            }
            .disabled(isSwitching || isDeleting || account.isCurrent)
        }
    }

    private var emailLine: String {
        (account.email ?? account.displayName).uppercased()
    }

    private var usageAccent: Color {
        if account.isCurrent {
            return StudioTheme.primary
        }
        return AccountPlanKind.resolve(account.effectivePlanType).usageAccent
    }

    private var currentContextPill: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(StudioTheme.primary)
            Text(currentPillTitle)
                .font(StudioFont.label(10))
                .foregroundStyle(StudioTheme.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(StudioTheme.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(StudioTheme.primary.opacity(0.2), lineWidth: 1)
        )
        .frame(maxWidth: 120, alignment: .trailing)
    }

    private var currentPillTitle: String {
        copy.currentPillTitle
    }
}

private struct StitchUsageStrip: View {
    let account: AccountSummary
    let accent: Color
    let copy: AppCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if snapshots.isEmpty {
                UsageMeterRow(
                    copy: copy,
                    section: .primary,
                    windowLabel: "—",
                    remainingHeadline: copy.syncing,
                    remainingHeadlineTint: StudioTheme.muted,
                    barFill: StudioTheme.outlineVariant.opacity(0.35),
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
                        windowLabel: snapshot.windowLabel,
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
        if let oneWeek = account.usage?.oneWeek {
            values.append(makeSnapshot(section: .primary, windowKind: .oneWeek, window: oneWeek))
        }
        if let fiveHour = account.usage?.fiveHour {
            values.append(makeSnapshot(section: .secondary, windowKind: .fiveHour, window: fiveHour))
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
            guard let remaining else {
                return StudioTheme.muted
            }
            if remaining >= 99.5 {
                if account.isCurrent && section == .secondary {
                    return StudioTheme.primary
                }
                return StudioTheme.ink
            }
            return accent
        }()
        let barFill: Color = {
            guard let remaining else {
                return StudioTheme.outlineVariant.opacity(0.35)
            }
            if remaining >= 99.5 {
                if account.isCurrent && section == .secondary {
                    return StudioTheme.primary.opacity(0.3)
                }
                return StudioTheme.outlineVariant.opacity(0.35)
            }
            return accent
        }()
        let barGlow: Color = {
            guard let remaining, remaining < 99.5 else {
                return .clear
            }
            return accent.opacity(0.28)
        }()
        let progress = max(0, min(remaining ?? 0, 100)) / 100
        let resetCaption: String = {
            if let used = window.usedPercent, used <= 0.01 {
                return copy.noActiveUsage
            }
            if let resetAt = window.resetAt {
                return relativeResetCaption(resetAt: resetAt, language: copy.language, copy: copy)
            }
            return "—"
        }()

        let windowLabel: String = {
            switch windowKind {
            case .oneWeek:
                return copy.oneWeekWindow
            case .fiveHour:
                return copy.fiveHourWindow
            }
        }()

        return UsageSnapshot(
            id: windowKind == .oneWeek ? "oneWeek" : "fiveHour",
            section: section,
            windowLabel: windowLabel,
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
        let windowLabel: String
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
        case primary
        case secondary
    }

    let copy: AppCopy
    let section: Section
    let windowLabel: String
    let remainingHeadline: String
    let remainingHeadlineTint: Color
    let barFill: Color
    let barGlow: Color
    let progress: Double
    let resetCaption: String

    private var sectionTitle: String {
        switch section {
        case .primary:
            return copy.primaryUsageSection
        case .secondary:
            return copy.secondaryUsageSection
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(sectionTitle)
                    .font(StudioFont.label(11))
                    .foregroundStyle(section == .secondary ? StudioTheme.muted : StudioTheme.ink)

                Spacer(minLength: 8)

                Text(remainingHeadline)
                    .font(StudioFont.label(11))
                    .foregroundStyle(remainingHeadlineTint)
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

            HStack(alignment: .firstTextBaseline) {
                Text(windowLabel)
                    .font(StudioFont.caption(10))
                    .foregroundStyle(StudioTheme.muted)

                Spacer(minLength: 8)

                Text(resetCaption)
                    .font(StudioFont.caption(10))
                    .foregroundStyle(StudioTheme.muted)
                    .multilineTextAlignment(.trailing)
            }
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
            return StudioTheme.primary.opacity(0.12)
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
            return StudioTheme.primary
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

private struct FooterUtilityButton: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(title)
                    .font(StudioFont.label(10))
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(StudioTheme.surfaceContainer.opacity(0.9))
            )
            .overlay(
                Capsule()
                    .stroke(StudioTheme.outlineVariant.opacity(0.14), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    /// 非当前账号用量条：与账户类型一一对应
    static let accentFree = adaptive(light: .rgba(0.55, 0.57, 0.62), dark: .rgba(0.647, 0.675, 0.733))
    static let accentPlus = adaptive(light: .rgba(0.08, 0.58, 0.53), dark: .rgba(0.471, 0.867, 0.780))
    static let accentTeamPlan = adaptive(light: .rgba(0.24, 0.34, 0.78), dark: .rgba(0.549, 0.620, 1.0))
    static let accentEnterprise = adaptive(light: .rgba(0.62, 0.42, 0.12), dark: .rgba(0.925, 0.733, 0.451))
    static let workspaceTeamBackground = adaptive(light: .rgba(0.89, 0.95, 1.0), dark: .rgba(0.137, 0.235, 0.365))
    static let workspaceTeamForeground = adaptive(light: .rgba(0.15, 0.39, 0.92), dark: .rgba(0.612, 0.796, 1.0))
    static let planFreeBackground = adaptive(light: .rgba(0.95, 0.96, 0.98), dark: .rgba(0.173, 0.184, 0.216))
    static let planFreeForeground = adaptive(light: .rgba(0.35, 0.40, 0.48), dark: .rgba(0.792, 0.816, 0.871))
    static let planPlusBackground = adaptive(light: .rgba(0.88, 0.97, 0.95), dark: .rgba(0.118, 0.263, 0.239))
    static let planPlusForeground = adaptive(light: .rgba(0.05, 0.45, 0.42), dark: .rgba(0.549, 0.933, 0.863))
    static let planTeamBackground = adaptive(light: .rgba(0.90, 0.92, 1.0), dark: .rgba(0.149, 0.180, 0.353))
    static let planTeamForeground = adaptive(light: .rgba(0.18, 0.25, 0.62), dark: .rgba(0.702, 0.749, 1.0))
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
}

private func usageDateFormatter(for language: AppLanguage) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: language.localeIdentifier)
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter
}

#Preview("Codex Switcher") {
    ContentView(model: AccountSwitcherViewModel())
        .frame(width: CodexSwitcherLayout.columnWidth, height: 760)
}
