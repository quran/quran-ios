//
//  FileSystemFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
import SystemDependencies

public struct ResourceValuesFake: ResourceValues {
    public let fileSize: Int?
}

public final class FileSystemFake: FileSystem, @unchecked Sendable {
    enum FileSystemError: Error {
        case noResourceValues
    }

    public init() {}

    public var files: Set<URL> = []
    public var checkedFiles: Set<URL> = []

    public func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }

    public var removedItems: [URL] = []
    public func removeItem(at url: URL) throws {
        removedItems.append(url)
    }

    public var filesInDirectory: [URL: [URL]] = [:]
    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
    }

    public var resourceValuesByURL: [URL: ResourceValuesFake] = [:]
    public func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues {
        if let values = resourceValuesByURL[url] {
            return values
        }
        throw FileSystemError.noResourceValues
    }

    public func setResourceValues(_ url: URL, fileSize: Int?) {
        resourceValuesByURL[url] = ResourceValuesFake(fileSize: fileSize)
    }
}
