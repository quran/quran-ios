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
    private struct State: Sendable {
        var files: Set<URL> = []
        var checkedFiles: Set<URL> = []
        var removedItems: [URL] = []
        var filesInDirectory: [URL: [URL]] = [:]
        var resourceValuesByURL: [URL: ResourceValuesFake] = [:]
    }

    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var files: Set<URL> {
        get { state.withCriticalRegion { $0.files } }
        set { state.withCriticalRegion { $0.files = newValue } }
    }

    public var checkedFiles: Set<URL> {
        get { state.withCriticalRegion { $0.checkedFiles } }
        set { state.withCriticalRegion { $0.checkedFiles = newValue } }
    }

    public var removedItems: [URL] {
        get { state.withCriticalRegion { $0.removedItems } }
        set { state.withCriticalRegion { $0.removedItems = newValue } }
    }

    public var filesInDirectory: [URL: [URL]] {
        get { state.withCriticalRegion { $0.filesInDirectory } }
        set { state.withCriticalRegion { $0.filesInDirectory = newValue } }
    }

    public var resourceValuesByURL: [URL: ResourceValuesFake] {
        get { state.withCriticalRegion { $0.resourceValuesByURL } }
        set { state.withCriticalRegion { $0.resourceValuesByURL = newValue } }
    }

    public func fileExists(at url: URL) -> Bool {
        checkedFiles.insert(url)
        return files.contains(url)
    }

    public func removeItem(at url: URL) throws {
        removedItems.append(url)
        files.remove(url)
    }

    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
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

    // MARK: Internal

    enum FileSystemError: Error {
        case noResourceValues
    }

    // MARK: Private

    private let state = ManagedCriticalState(State())
}
