import SwiftUI

/// 主窗口与 sheet 共用列宽，避免弹层比窗口更宽。
private enum CodexSwitcherLayout {
    static let columnWidth: CGFloat = 390
}

@main
struct CodexSwitcherApp: App {
    @StateObject private var model = AccountSwitcherViewModel()

    var body: some Scene {
        WindowGroup("Codex Switcher") {
            ContentView(model: model)
                .frame(minWidth: CodexSwitcherLayout.columnWidth, idealWidth: CodexSwitcherLayout.columnWidth, maxWidth: 430, minHeight: 760)
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
    @Published var noticeMessage: String?

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

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            accounts = try await accountService.refreshUsageForAllAccounts()
            if accounts.isEmpty {
                noticeMessage = "Copool 里还没有可切换的账号。"
            } else {
                noticeMessage = nil
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
            noticeMessage = "已切换到 \(switched.displayName)，并启动 Codex。"
            errorMessage = nil
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addAccountViaLogin() async {
        isLoggingIn = true
        defer { isLoggingIn = false }

        do {
            let imported = try await accountService.addAccountViaLogin()
            noticeMessage = "已登录并添加账号 \(imported.displayName)"
            errorMessage = nil
            await load()
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
            noticeMessage = "已删除 \(deleted.displayName)"
            errorMessage = nil
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ContentView: View {
    @ObservedObject var model: AccountSwitcherViewModel

    var body: some View {
        ZStack {
            StudioBackground()

            ScrollView {
                LazyVStack(spacing: 16) {
                    banner

                    if model.isLoading && model.accounts.isEmpty {
                        loadingBlock
                    } else if model.accounts.isEmpty {
                        EmptyAccountsCard()
                    } else {
                        ForEach(model.accounts) { account in
                            AccountCard(
                                account: account,
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
            "删除这个账号？",
            isPresented: Binding(
                get: { model.pendingDeletionAccount != nil },
                set: { isPresented in
                    if !isPresented {
                        model.cancelDelete()
                    }
                }
            )
        ) {
            Button("删除", role: .destructive) {
                Task {
                    await model.deletePendingAccount()
                }
            }
            Button("取消", role: .cancel) {
                model.cancelDelete()
            }
        } message: {
            if let account = model.pendingDeletionAccount {
                Text("将从 Copool 保存列表中移除 \(account.displayName)。当前账号不能删除。")
            } else {
                Text("将从 Copool 保存列表中移除此账号。")
            }
        }
    }

    private var loadingBlock: some View {
        VStack(spacing: 14) {
            ProgressView("正在读取账号并刷新用量...")
                .tint(StudioTheme.primary)
                .foregroundStyle(StudioTheme.muted)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    @ViewBuilder
    private var banner: some View {
        if let message = model.errorMessage {
            StatusBanner(message: message, icon: "exclamationmark.triangle.fill", tint: StudioTheme.danger)
        } else if let message = model.noticeMessage {
            StatusBanner(message: message, icon: "checkmark.circle.fill", tint: StudioTheme.success)
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
                    Text(model.isLoggingIn ? "登录中…" : "登录新增账号")
                        .font(StudioFont.label(12))
                }
                .foregroundStyle(StudioTheme.primary)
            }
            .buttonStyle(.plain)
            .disabled(model.isLoggingIn || model.isLoading || model.switchingAccountID != nil || model.deletingAccountID != nil)

            Spacer(minLength: 12)

            Button {
                Task {
                    await model.load()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .regular))
                    Text("重新加载")
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
                            StitchChip(text: "CURRENT", style: .current)
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
                            Text("SWITCH")
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

            StitchUsageStrip(account: account, accent: usageAccent)
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
                Label(isDeleting ? "删除中…" : "删除账号", systemImage: "trash")
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
        "CURRENT"
    }
}

private struct StitchUsageStrip: View {
    let account: AccountSummary
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if snapshots.isEmpty {
                UsageMeterRow(
                    section: .primary,
                    windowLabel: "—",
                    remainingHeadline: "SYNCING",
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
        let remainingHeadline = remaining.map { "\(Int($0.rounded()))% Remaining" } ?? "SYNCING"
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
                return "No active usage"
            }
            if let resetAt = window.resetAt {
                return relativeResetCaption(resetAt: resetAt)
            }
            return "—"
        }()

        let windowLabel: String = {
            switch windowKind {
            case .oneWeek:
                return "1 week window"
            case .fiveHour:
                return "5 hour window"
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
            return "Resources Usage"
        case .secondary:
            return "Usage (secondary)"
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

private func relativeResetCaption(resetAt: Int64) -> String {
    let date = Date(timeIntervalSince1970: TimeInterval(resetAt))
    let calendar = Calendar.current
    let startNow = calendar.startOfDay(for: Date())
    let startTarget = calendar.startOfDay(for: date)
    let days = calendar.dateComponents([.day], from: startNow, to: startTarget).day ?? 0
    if days > 0 {
        return "Resets in \(days) days"
    }
    if days < 0 {
        return "Resets \(usageDateFormatter.string(from: date))"
    }
    return "Resets today"
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
            return Color(red: 0.89, green: 0.95, blue: 1.0)
        case .planFree:
            return Color(red: 0.95, green: 0.96, blue: 0.98)
        case .planPlus:
            return Color(red: 0.88, green: 0.97, blue: 0.95)
        case .planPro:
            return StudioTheme.tertiaryContainer
        case .planTeam:
            return Color(red: 0.90, green: 0.92, blue: 1.0)
        case .planEnterprise:
            return Color(red: 1.0, green: 0.95, blue: 0.88)
        case .neutral:
            return StudioTheme.secondaryContainer
        }
    }

    private var foreground: Color {
        switch style {
        case .current:
            return StudioTheme.primary
        case .workspaceTeam:
            return Color(red: 0.15, green: 0.39, blue: 0.92)
        case .planFree:
            return Color(red: 0.35, green: 0.40, blue: 0.48)
        case .planPlus:
            return Color(red: 0.05, green: 0.45, blue: 0.42)
        case .planPro:
            return StudioTheme.onTertiaryContainer
        case .planTeam:
            return Color(red: 0.18, green: 0.25, blue: 0.62)
        case .planEnterprise:
            return Color(red: 0.45, green: 0.30, blue: 0.08)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("还没有可切换账号")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(StudioTheme.ink)

            Text("登录一个新账号后，这里会自动生成可切换卡片。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(StudioTheme.muted)

            VStack(alignment: .leading, spacing: 6) {
                Text("读取路径：~/Library/Application Support/CodexToolsSwift/accounts.json")
                Text("当前 auth 路径：~/.codex/auth.json")
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
            .fill(Color.white.opacity(fillOpacity))
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
    static let canvasTop = Color(red: 0.984, green: 0.973, blue: 0.988)
    static let primary = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let primaryContainer = Color(red: 0.188, green: 0.533, blue: 0.965)
    static let secondary = Color(red: 0.349, green: 0.373, blue: 0.431)
    static let secondaryContainer = Color(red: 0.867, green: 0.886, blue: 0.957)
    static let onSecondaryContainer = Color(red: 0.298, green: 0.322, blue: 0.376)
    static let tertiary = Color(red: 0.482, green: 0.322, blue: 0.431)
    static let tertiaryContainer = Color(red: 0.980, green: 0.773, blue: 0.902)
    static let onTertiaryContainer = Color(red: 0.388, green: 0.239, blue: 0.345)
    static let surfaceContainer = Color(red: 0.933, green: 0.929, blue: 0.953)
    static let surfaceContainerLow = Color(red: 0.957, green: 0.953, blue: 0.973)
    static let surfaceContainerHighest = Color(red: 0.886, green: 0.886, blue: 0.922)
    static let outlineVariant = Color(red: 0.694, green: 0.694, blue: 0.725)
    static let success = Color(red: 0.164, green: 0.498, blue: 0.334)
    static let danger = Color(red: 0.749, green: 0.282, blue: 0.341)
    static let ink = Color(red: 0.188, green: 0.196, blue: 0.22)
    static let muted = Color(red: 0.365, green: 0.373, blue: 0.396)
    static let ghostBorder = Color(red: 0.694, green: 0.694, blue: 0.725).opacity(0.18)
    static let shadow = Color(red: 0.188, green: 0.196, blue: 0.22).opacity(0.06)
    static let footerFill = Color(red: 0.976, green: 0.980, blue: 0.984).opacity(0.82)
    static let footerMuted = Color(red: 0.608, green: 0.627, blue: 0.651)
    static let footerTopBorder = Color(red: 0.88, green: 0.89, blue: 0.92).opacity(0.35)
    static let footerShadow = Color.black.opacity(0.05)

    /// 非当前账号用量条：与账户类型一一对应
    static let accentFree = Color(red: 0.55, green: 0.57, blue: 0.62)
    static let accentPlus = Color(red: 0.08, green: 0.58, blue: 0.53)
    static let accentTeamPlan = Color(red: 0.24, green: 0.34, blue: 0.78)
    static let accentEnterprise = Color(red: 0.62, green: 0.42, blue: 0.12)

}

private let usageDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter
}()

#Preview("Codex Switcher") {
    ContentView(model: AccountSwitcherViewModel())
        .frame(width: CodexSwitcherLayout.columnWidth, height: 760)
}
