//
//  Zipper.swift
//
//
//  Created by Mohamed Afifi on 2023-11-22.
//

import Foundation
import ZIPFoundation

public protocol Zipper {
    func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool) throws
}

public struct DefaultZipper: Zipper {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    /// Extracts `zipFile` into `destination`, throwing for entries that would land outside it.
    /// With `overwrite`, files already at an entry's path are replaced; otherwise extraction fails on them.
    public func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool) throws {
        let fileManager = FileManager.default
        if overwrite {
            try removeItemsReplaced(by: zipFile, in: destination, fileManager: fileManager)
        }
        try fileManager.unzipItem(at: zipFile, to: destination)
    }

    // MARK: Private

    private func removeItemsReplaced(by zipFile: URL, in destination: URL, fileManager: FileManager) throws {
        let archive = try Archive(url: zipFile, accessMode: .read)
        // Validate every entry before deleting anything, so a crafted archive cannot delete files outside `destination`.
        let replacedItems = try archive
            .filter { $0.type != .directory }
            .map { try containedURL(for: $0.path, in: destination) }
        for item in replacedItems where (try? item.checkResourceIsReachable()) == true {
            try fileManager.removeItem(at: item)
        }
    }

    private func containedURL(for entryPath: String, in destination: URL) throws -> URL {
        var depth = 0
        for component in entryPath.split(separator: "/") {
            switch component {
            case ".": continue
            case "..": depth -= 1
            default: depth += 1
            }
            guard depth >= 0 else {
                throw CocoaError(.fileReadInvalidFileName, userInfo: [NSFilePathErrorKey: entryPath])
            }
        }
        return destination.appendingPathComponent(entryPath)
    }
}
