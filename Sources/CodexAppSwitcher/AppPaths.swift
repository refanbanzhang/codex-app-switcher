import Foundation

struct AppPaths {
    let appSupportDirectory: URL
    let accountStorePath: URL
    let codexAuthPath: URL
    let codexConfigPath: URL
    let authBackupDirectory: URL

    private static let appSupportFolderName = "codex-app-switcher"
    private static let legacyAppSupportFolderName = "CodexToolsSwift"

    static func live(fileManager: FileManager = .default) throws -> AppPaths {
        let appSupportBase = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let appSupportDirectory = appSupportBase.appendingPathComponent(Self.appSupportFolderName, isDirectory: true)
        let newAccounts = appSupportDirectory.appendingPathComponent("accounts.json", isDirectory: false)
        let legacyDirectory = appSupportBase.appendingPathComponent(Self.legacyAppSupportFolderName, isDirectory: true)
        let legacyAccounts = legacyDirectory.appendingPathComponent("accounts.json", isDirectory: false)

        if !fileManager.fileExists(atPath: newAccounts.path),
           fileManager.fileExists(atPath: legacyAccounts.path) {
            try fileManager.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true)
            try fileManager.copyItem(at: legacyAccounts, to: newAccounts)
            let legacyBackups = legacyDirectory.appendingPathComponent("auth-backups", isDirectory: true)
            let newBackups = appSupportDirectory.appendingPathComponent("auth-backups", isDirectory: true)
            if fileManager.fileExists(atPath: legacyBackups.path),
               !fileManager.fileExists(atPath: newBackups.path) {
                try fileManager.copyItem(at: legacyBackups, to: newBackups)
            }
        }

        let codexAuthPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json", isDirectory: false)
        let codexConfigPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("config.toml", isDirectory: false)

        return AppPaths(
            appSupportDirectory: appSupportDirectory,
            accountStorePath: appSupportDirectory.appendingPathComponent("accounts.json", isDirectory: false),
            codexAuthPath: codexAuthPath,
            codexConfigPath: codexConfigPath,
            authBackupDirectory: appSupportDirectory.appendingPathComponent("auth-backups", isDirectory: true)
        )
    }
}
