//
//  ZipperFake.swift
//
//
//  Created by Mohamed Afifi on 2023-11-22.
//

import Foundation
import SystemDependencies

public final class ZipperFake: Zipper {
    public struct PartialFailure {
        public let error: Error
        public let writtenFiles: Int

        public init(error: Error, writtenFiles: Int) {
            self.error = error
            self.writtenFiles = writtenFiles
        }
    }

    // MARK: Lifecycle

    public init(fileManager: FileSystem) {
        self.fileManager = fileManager
    }

    // MARK: Public

    public var failures: [Error] = []
    public var partialFailure: PartialFailure?
    public var unzippedFiles: [URL] = []

    public func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool, password: String?) throws {
        let files = zipContents(zipFile).sorted { $0.path < $1.path }

        if let partialFailure {
            self.partialFailure = nil
            for file in files.prefix(partialFailure.writtenFiles) {
                try fileManager.writeToFile(at: file, content: "unzipped")
            }
            throw partialFailure.error
        }

        if let failure = failures.first {
            failures.remove(at: 0)
            throw failure
        }

        for file in files {
            try fileManager.writeToFile(at: file, content: "unzipped")
        }
        unzippedFiles.append(zipFile)
    }

    public func zipContents(_ zipFile: URL) -> Set<URL> {
        let directory = zipFile.deletingPathExtension()
        return [
            directory.appendingPathComponent("text.txt"),
            directory.appendingPathComponent("database.db"),
            directory.appendingPathComponent("image.png"),
        ]
    }

    // MARK: Private

    private let fileManager: FileSystem
}
