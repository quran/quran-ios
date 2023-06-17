//
//  FileSystem.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation

public protocol FileSystem: Sendable {
    func fileExists(at url: URL) -> Bool
    func removeItem(at url: URL) throws
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL]
    func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues
}

public struct DefaultFileSystem: FileSystem {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public func fileExists(at url: URL) -> Bool {
        (try? url.checkResourceIsReachable()) ?? false
    }

    public func removeItem(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    public func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues {
        try url.resourceValues(forKeys: keys)
    }
}

public protocol ResourceValues {
    var fileSize: Int? { get }
}

extension URLResourceValues: ResourceValues { }
