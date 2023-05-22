//
//  FileSystemFake.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
import SystemDependencies
import Utilities

public struct ResourceValuesFake: ResourceValues, Sendable {
    public let fileSize: Int?
}

public final class FileSystemFake: FileSystem, Sendable {
    enum FileSystemError: Error {
        case noResourceValues
    }

    private struct State: Sendable {
        var files: Set<URL> = []
        var checkedFiles: Set<URL> = []
        var removedItems: [URL] = []
        var filesInDirectory: [URL: [URL]] = [:]
        var resourceValuesByURL: [URL: ResourceValuesFake] = [:]
    }

    private let state = ManagedCriticalState(State())

    public init() {}

    public var files: Set<URL> {
        get { state.withCriticalRegion { $0.files } }
        set { state.withCriticalRegion { $0.files = newValue } }
    }

    public var checkedFiles: Set<URL> {
        get { state.withCriticalRegion { $0.checkedFiles } }
        set { state.withCriticalRegion { $0.checkedFiles = newValue } }
    }

    public func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }

    public var removedItems: [URL] {
        get { state.withCriticalRegion { $0.removedItems } }
        set { state.withCriticalRegion { $0.removedItems = newValue } }
    }

    public func removeItem(at url: URL) throws {
        removedItems.append(url)
        files.remove(url)
    }

    public var filesInDirectory: [URL: [URL]] {
        get { state.withCriticalRegion { $0.filesInDirectory } }
        set { state.withCriticalRegion { $0.filesInDirectory = newValue } }
    }

    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
    }

    public var resourceValuesByURL: [URL: ResourceValuesFake] {
        get { state.withCriticalRegion { $0.resourceValuesByURL } }
        set { state.withCriticalRegion { $0.resourceValuesByURL = newValue } }
    }

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
