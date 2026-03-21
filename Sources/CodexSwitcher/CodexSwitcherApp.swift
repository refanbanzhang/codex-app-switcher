import SwiftUI

@main
struct CodexSwitcherApp: App {
    @StateObject private var model = AccountSwitcherViewModel()

    var body: some Scene {
        WindowGroup("Codex Switcher") {
            ContentView(model: model)
                .frame(minWidth: 390, idealWidth: 390, maxWidth: 430, minHeight: 760)
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
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.92, blue: 0.86),
                    Color(red: 0.86, green: 0.92, blue: 0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                header
                statusBar
                accountList
                footer
            }
            .padding(16)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Codex Switcher")
                .font(.system(size: 26, weight: .bold, design: .rounded))
            Text("只保留切换账号的核心功能，直接读取 Copool 已保存的账号。")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var statusBar: some View {
        if let message = model.errorMessage {
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let message = model.noticeMessage {
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.10, green: 0.45, blue: 0.26))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var accountList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if model.isLoading {
                    ProgressView("正在读取账号并刷新用量...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 80)
                } else if model.accounts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("没有找到账号")
                            .font(.headline)
                        Text("读取路径：~/Library/Application Support/CodexToolsSwift/accounts.json")
                            .foregroundStyle(.secondary)
                        Text("当前 auth 路径：~/.codex/auth.json")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            .padding(.vertical, 4)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(model.isLoggingIn ? "登录中..." : "登录新增账号") {
                Task {
                    await model.addAccountViaLogin()
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .disabled(model.isLoggingIn || model.isLoading || model.switchingAccountID != nil || model.deletingAccountID != nil)

            Button("重新加载") {
                Task {
                    await model.load()
                }
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            .disabled(model.isLoggingIn || model.deletingAccountID != nil)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(account.displayName)
                            .font(.headline)
                        if account.isCurrent {
                            Tag(text: "CURRENT", tint: Color.accentColor)
                        }
                    }

                    if let secondaryText {
                        Text(secondaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 8)

                HStack(spacing: 8) {
                    Button(isDeleting ? "删除中" : "删除") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                    .disabled(isSwitching || isDeleting || account.isCurrent)

                    Button(isSwitching ? "切换中" : (account.isCurrent ? "当前" : "切换")) {
                        onSwitch()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .disabled(isSwitching || isDeleting || account.isCurrent)
                }
            }

            HStack(spacing: 6) {
                if let planType = account.effectivePlanType, !planType.isEmpty {
                    Tag(text: planType.uppercased(), tint: Color.orange)
                }
                if let teamName = account.teamName, !teamName.isEmpty {
                    Tag(text: teamName, tint: Color.teal)
                }
            }

            if account.usage?.fiveHour != nil || account.usage?.oneWeek != nil {
                CompactUsageSection(account: account)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(account.isCurrent ? Color.accentColor.opacity(0.35) : Color.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var secondaryText: String? {
        guard let email = account.email?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty else {
            return nil
        }
        return email.caseInsensitiveCompare(account.displayName) == .orderedSame ? nil : email
    }
}

private struct CompactUsageSection: View {
    let account: AccountSummary

    var body: some View {
        VStack(spacing: 8) {
            if let fiveHour = account.usage?.fiveHour {
                UsageRow(title: "5h", window: fiveHour)
            }

            if let oneWeek = account.usage?.oneWeek {
                UsageRow(title: "1w", window: oneWeek)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.28), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct UsageRow: View {
    let title: String
    let window: UsageWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, alignment: .leading)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                        Capsule()
                            .fill(progressTint.gradient)
                            .frame(width: proxy.size.width * progressFraction)
                    }
                }
                .frame(height: 6)

                Text(remainingText)
                    .font(.caption2.monospacedDigit().weight(.semibold))
                    .foregroundStyle(progressTint)
            }

            if let resetText {
                Text("重置 \(resetText)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 30)
            }
        }
    }

    private var remainingText: String {
        guard let remaining = window.remainingPercent else {
            return "--"
        }
        return "\(Int(remaining.rounded()))%"
    }

    private var progressFraction: CGFloat {
        guard let remaining = window.remainingPercent else {
            return 0
        }
        return CGFloat(remaining / 100)
    }

    private var progressTint: Color {
        guard let remaining = window.remainingPercent else {
            return .gray
        }
        switch remaining {
        case 60...:
            return Color(red: 0.10, green: 0.53, blue: 0.31)
        case 25...:
            return Color.orange
        default:
            return Color.red
        }
    }

    private var resetText: String? {
        guard let resetAt = window.resetAt else {
            return nil
        }
        return usageDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(resetAt)))
    }
}

private struct Tag: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
            .foregroundStyle(tint)
    }
}

private let usageDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "MM-dd HH:mm"
    return formatter
}()

#Preview("Codex Switcher") {
    ContentView(model: AccountSwitcherViewModel())
        .frame(width: 390, height: 760)
}
