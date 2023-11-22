//
//  ZipperFake.swift
//
//
//  Created by Mohamed Afifi on 2023-11-22.
//

import Foundation
import SystemDependencies

public final class ZipperFake: Zipper {
    // MARK: Lifecycle

    public init(fileManager: FileSystem) {
        self.fileManager = fileManager
    }

    // MARK: Public

    public var failures: [Error] = []
    public var unzippedFiles: [URL] = []

    public func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool, password: String?) throws {
        if let failure = failures.first {
            failures.remove(at: 0)
            throw failure
        }

        for file in zipContents(zipFile) {
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
