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

    enum FileSystemError: Error {
        case noResourceValues
        case general(String)
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
        for file in files {
            if url.isParent(of: file) {
                files.remove(file)
            }
        }
    }

    public func moveItem(at src: URL, to dst: URL) throws {
        if !files.contains(src) {
            throw FileSystemError.general("Source file doesn't exist: \(src)")
        }
        if files.contains(dst) {
            throw FileSystemError.general("Destination file exists: \(src)")
        }
        files.remove(src)
        files.insert(dst)
    }

    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        filesInDirectory[url] ?? []
    }

    public func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        files.insert(url)
    }

    public func copyItem(at srcURL: URL, to dstURL: URL) throws {
        files.insert(dstURL)
        let parent = dstURL.deletingLastPathComponent()
        var contents = filesInDirectory[parent] ?? []
        contents.append(dstURL)
        filesInDirectory[parent] = contents
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

    public func writeToFile(at path: URL, content: String) throws {
        if files.contains(path) {
            throw FileSystemError.general("Cannot overwrite file at \(path)")
        }
        files.insert(path)
    }

    // MARK: Private

    private let state = ManagedCriticalState(State())
}
