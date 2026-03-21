import AppKit
import Foundation

struct CodexAppController {
    private let bundleIdentifier = "com.openai.codex"
    private let applicationName = "Codex"

    @MainActor
    func relaunchOrLaunch() async throws {
        let runningApp = runningApplication()
        let appURL = resolvedAppURL(for: runningApp)
        guard let appURL else {
            throw CLIError("已切换账号，但没有找到 Codex App 的安装位置，无法自动启动 Codex。")
        }

        if let runningApp {
            runningApp.terminate()
            try await waitForTermination(of: runningApp, timeoutNanoseconds: 5_000_000_000)

            if !runningApp.isTerminated {
                runningApp.forceTerminate()
                try await waitForTermination(of: runningApp, timeoutNanoseconds: 3_000_000_000)
            }

            guard runningApp.isTerminated else {
                throw CLIError("已切换账号，但 Codex App 未能正常退出，请手动重启 Codex。")
            }
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }

    }

    @MainActor
    private func runningApplication() -> NSRunningApplication? {
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
        if let app = apps.first {
            return app
        }

        return NSWorkspace.shared.runningApplications.first { app in
            app.localizedName == applicationName
        }
    }

    @MainActor
    private func resolvedAppURL(for app: NSRunningApplication?) -> URL? {
        if let bundleURL = app?.bundleURL {
            return bundleURL
        }
        if let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return bundleURL
        }
        return nil
    }

    private func waitForTermination(
        of app: NSRunningApplication,
        timeoutNanoseconds: UInt64
    ) async throws {
        let deadline = DispatchTime.now().uptimeNanoseconds + timeoutNanoseconds
        while !app.isTerminated && DispatchTime.now().uptimeNanoseconds < deadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
