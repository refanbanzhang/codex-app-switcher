import Foundation

struct AppPaths {
    let copoolAppSupportDirectory: URL
    let accountStorePath: URL
    let codexAuthPath: URL
    let codexConfigPath: URL
    let authBackupDirectory: URL

    static func live(fileManager: FileManager = .default) throws -> AppPaths {
        let appSupportBase = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let copoolAppSupportDirectory = appSupportBase.appendingPathComponent("CodexToolsSwift", isDirectory: true)
        let codexAuthPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("auth.json", isDirectory: false)
        let codexConfigPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".codex", isDirectory: true)
            .appendingPathComponent("config.toml", isDirectory: false)

        return AppPaths(
            copoolAppSupportDirectory: copoolAppSupportDirectory,
            accountStorePath: copoolAppSupportDirectory.appendingPathComponent("accounts.json", isDirectory: false),
            codexAuthPath: codexAuthPath,
            codexConfigPath: codexConfigPath,
            authBackupDirectory: copoolAppSupportDirectory.appendingPathComponent("auth-backups", isDirectory: true)
        )
    }
}
