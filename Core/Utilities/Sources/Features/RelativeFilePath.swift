//
//  RelativeFilePath.swift
//
//
//  Created by Mohamed Afifi on 2023-07-09.
//

import Foundation

public struct RelativeFilePath: Hashable, Sendable {
    // MARK: Lifecycle

    public init(_ path: String, isDirectory: Bool) {
        self.path = path
        self.isDirectory = isDirectory
    }

    // MARK: Public

    public let path: String

    public var url: URL { FileManager.documentsURL.appendingPathComponent(path, isDirectory: isDirectory) }

    // MARK: Private

    private let isDirectory: Bool
}

public extension RelativeFilePath {
    var isReachable: Bool { url.isReachable }

    func isParent(of child: RelativeFilePath) -> Bool {
        child.path.hasPrefix(path)
    }

    var lastPathComponent: String { url.lastPathComponent }

    func appendingPathComponent(_ pathComponent: String, isDirectory: Bool) -> RelativeFilePath {
        RelativeFilePath(path.stringByAppendingPath(pathComponent), isDirectory: isDirectory)
    }

    func appendingPathExtension(_ pathExtension: String) -> RelativeFilePath {
        RelativeFilePath(path.appending("." + pathExtension), isDirectory: false)
    }

    func deletingLastPathComponent() -> RelativeFilePath {
        RelativeFilePath(path.stringByDeletingLastPathComponent, isDirectory: true)
    }

    func deletingPathExtension() -> RelativeFilePath {
        RelativeFilePath(path.stringByDeletingPathExtension, isDirectory: true)
    }
}

public extension FileManager {
    func removeItem(at path: RelativeFilePath) throws {
        try removeItem(at: path.url)
    }

    func createDirectory(at path: RelativeFilePath, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]? = nil) throws {
        try createDirectory(at: path.url, withIntermediateDirectories: withIntermediateDirectories, attributes: attributes)
    }

    func moveItem(at src: URL, to dst: RelativeFilePath) throws {
        try moveItem(at: src, to: dst.url)
    }

    func copyItem(at src: URL, to dst: RelativeFilePath) throws {
        try copyItem(at: src, to: dst.url)
    }
}

public extension Data {
    init(contentsOf path: RelativeFilePath, options: Data.ReadingOptions = []) throws {
        try self.init(contentsOf: path.url, options: options)
    }

    func write(to path: RelativeFilePath, options: Data.WritingOptions = []) throws {
        try write(to: path.url, options: options)
    }
}

public extension String {
    init(contentsOf path: RelativeFilePath) throws {
        try self.init(contentsOf: path.url)
    }

    func write(to path: RelativeFilePath, atomically: Bool, encoding: String.Encoding) throws {
        try write(to: path.url, atomically: atomically, encoding: encoding)
    }
}
