import Foundation

struct StoreRepository {
    let paths: AppPaths
    private let fileManager: FileManager = .default

    func loadOrEmpty() throws -> AccountStore {
        guard fileManager.fileExists(atPath: paths.accountStorePath.path) else {
            return AccountStore()
        }

        let data = try Data(contentsOf: paths.accountStorePath)
        return try JSONDecoder().decode(AccountStore.self, from: data)
    }

    func load() throws -> AccountStore {
        guard fileManager.fileExists(atPath: paths.accountStorePath.path) else {
            throw CLIError("Account store not found at \(paths.accountStorePath.path)")
        }

        return try loadOrEmpty()
    }

    func save(_ store: AccountStore) throws {
        try fileManager.createDirectory(at: paths.appSupportDirectory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(store)
        try data.write(to: paths.accountStorePath, options: .atomic)
    }
}
