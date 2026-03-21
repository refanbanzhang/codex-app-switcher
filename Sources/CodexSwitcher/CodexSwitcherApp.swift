import SwiftUI

@main
struct CodexSwitcherApp: App {
    @StateObject private var model = AccountSwitcherViewModel()

    var body: some Scene {
        WindowGroup("Codex Switcher") {
            ContentView(model: model)
                .frame(minWidth: 620, minHeight: 520)
        }
        .windowResizability(.contentSize)
    }
}

@MainActor
final class AccountSwitcherViewModel: ObservableObject {
    @Published var accounts: [AccountSummary] = []
    @Published var isLoading = false
    @Published var switchingAccountID: String?
    @Published var errorMessage: String?
    @Published var noticeMessage: String?

    private let accountService: AccountService

    init() {
        do {
            let paths = try AppPaths.live()
            let authRepository = AuthRepository(paths: paths)
            let storeRepository = StoreRepository(paths: paths)
            self.accountService = AccountService(authRepository: authRepository, storeRepository: storeRepository)
        } catch {
            self.accountService = AccountService(
                authRepository: AuthRepository(paths: AppPaths(
                    copoolAppSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                )),
                storeRepository: StoreRepository(paths: AppPaths(
                    copoolAppSupportDirectory: URL(fileURLWithPath: "/"),
                    accountStorePath: URL(fileURLWithPath: "/"),
                    codexAuthPath: URL(fileURLWithPath: "/"),
                    authBackupDirectory: URL(fileURLWithPath: "/")
                ))
            )
            self.errorMessage = error.localizedDescription
        }
    }

    func load() {
        isLoading = true
        defer { isLoading = false }

        do {
            try accountService.syncCurrentAuthAccountOnStartup()
            accounts = try accountService.listAccounts()
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

    func switchAccount(_ account: AccountSummary) {
        switchingAccountID = account.id
        defer { switchingAccountID = nil }

        do {
            let switched = try accountService.switchAccount(identifier: account.id)
            noticeMessage = "已切换到 \(switched.displayName)"
            errorMessage = nil
            load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importCurrentAuth() {
        do {
            let imported = try accountService.importCurrentAuth()
            noticeMessage = "已导入当前账号 \(imported.displayName)"
            errorMessage = nil
            load()
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
            .padding(24)
        }
        .task {
            model.load()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Codex Switcher")
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("只保留切换账号的核心功能，直接读取 Copool 已保存的账号。")
                .font(.system(size: 14, weight: .medium, design: .rounded))
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
            LazyVStack(spacing: 14) {
                if model.isLoading {
                    ProgressView("正在读取账号...")
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
                            onSwitch: { model.switchAccount(account) }
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var footer: some View {
        HStack {
            Button("导入当前账号") {
                model.importCurrentAuth()
            }
            .buttonStyle(.bordered)

            Button("重新加载") {
                model.load()
            }
            .buttonStyle(.bordered)
        }
    }
}

private struct AccountCard: View {
    let account: AccountSummary
    let isSwitching: Bool
    let onSwitch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(account.displayName)
                            .font(.headline)
                        if account.isCurrent {
                            Tag(text: "CURRENT", tint: Color.accentColor)
                        }
                    }

                    if let email = account.email, !email.isEmpty {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button(isSwitching ? "切换中..." : (account.isCurrent ? "当前账号" : "切换到这个账号")) {
                    onSwitch()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSwitching || account.isCurrent)
            }

            HStack(spacing: 8) {
                Tag(text: account.accountID, tint: Color.black.opacity(0.7))
                if let planType = account.planType, !planType.isEmpty {
                    Tag(text: planType.uppercased(), tint: Color.orange)
                }
                if let teamName = account.teamName, !teamName.isEmpty {
                    Tag(text: teamName, tint: Color.teal)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(account.isCurrent ? Color.accentColor.opacity(0.35) : Color.white.opacity(0.18), lineWidth: 1)
        )
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

#Preview("Codex Switcher") {
    ContentView(model: AccountSwitcherViewModel())
        .frame(width: 620, height: 520)
}
