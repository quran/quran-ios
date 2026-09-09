import AppMigrator
import Foundation
import SystemDependencies
import Utilities
import VLogging

public struct DownloadBackupMigrator: Migrator {
    // MARK: Lifecycle

    public init() {
        self.init(documentsURL: FileManager.documentsURL)
    }

    init(documentsURL: URL) {
        self.documentsURL = documentsURL
    }

    // MARK: Public

    public var blocksUI: Bool { false }
    public var uiTitle: String? { nil }

    public func execute(update: LaunchVersionUpdate) async {
        for name in ["audio_files", "translations", "readings"] {
            let directory = documentsURL.appendingPathComponent(name, isDirectory: true)
            do {
                // Older file migrations run concurrently and may populate these directories later.
                try fileSystem.createDirectory(at: directory, withIntermediateDirectories: true)
                try fileSystem.setExcludedFromBackup(true, at: directory)
            } catch {
                logger.error("Couldn't exclude downloaded resources at \(directory) from backup. Error: \(error)")
            }
        }
    }

    // MARK: Private

    private let documentsURL: URL
    private let fileSystem = DefaultFileSystem()
}
