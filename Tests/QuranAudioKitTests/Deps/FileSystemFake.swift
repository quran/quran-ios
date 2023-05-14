//
//  FileSystemFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
@testable import QuranAudioKit

struct ResourceValuesFake: ResourceValues {
    let fileSize: Int?
}

final class FileSystemFake: FileSystem, @unchecked Sendable {
    enum FileSystemError: Error {
        case noResourceValues
    }

    var files: Set<URL> = []
    var checkedFiles: Set<URL> = []

    func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }

    var removedItems: [URL] = []
    func removeItem(at url: URL) throws {
        removedItems.append(url)
    }

    var filesInDirectory: [URL: [URL]] = [:]
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
    }

    var resourceValuesByURL: [URL: ResourceValuesFake] = [:]
    func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues {
        if let values = resourceValuesByURL[url] {
            return values
        }
        throw FileSystemError.noResourceValues
    }

    func setResourceValues(_ url: URL, fileSize: Int?) {
        resourceValuesByURL[url] = ResourceValuesFake(fileSize: fileSize)
    }
}
