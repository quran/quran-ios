//
//  FileSystem.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import Foundation
import Utilities

public protocol FileSystem: Sendable {
    func fileExists(at url: URL) -> Bool
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at url: URL) throws
    func moveItem(at src: URL, to dst: URL) throws
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL]
    func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues

    func writeToFile(at path: URL, content: String) throws
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

    public func moveItem(at src: URL, to dst: URL) throws {
        try FileManager.default.moveItem(at: src, to: dst)
    }

    public func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    }

    public func resourceValues(at url: URL, forKeys keys: Set<URLResourceKey>) throws -> ResourceValues {
        try url.resourceValues(forKeys: keys)
    }

    public func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: createIntermediates)
    }

    public func copyItem(at srcURL: URL, to dstURL: URL) throws {
        try FileManager.default.copyItem(at: srcURL, to: dstURL)
    }

    public func writeToFile(at path: URL, content: String) throws {
        try "Success".write(to: path, atomically: true, encoding: .utf8)
    }
}

public protocol ResourceValues {
    var fileSize: Int? { get }
}

extension URLResourceValues: ResourceValues { }

public extension FileSystem {
    func contentsOfDirectory(at path: RelativeFilePath, includingPropertiesForKeys keys: [URLResourceKey]?) throws -> [URL] {
        try contentsOfDirectory(at: path.url, includingPropertiesForKeys: keys)
    }

    func fileExists(at path: RelativeFilePath) -> Bool {
        fileExists(at: path.url)
    }

    func removeItem(at path: RelativeFilePath) throws {
        try removeItem(at: path.url)
    }

    func createDirectory(at path: RelativeFilePath, withIntermediateDirectories: Bool) throws {
        try createDirectory(at: path.url, withIntermediateDirectories: withIntermediateDirectories)
    }

    func moveItem(at src: URL, to dst: RelativeFilePath) throws {
        try moveItem(at: src, to: dst.url)
    }
}
