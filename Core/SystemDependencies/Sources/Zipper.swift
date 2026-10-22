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
    /// With `overwrite`, each file already at an entry's path is swapped in atomically, and existing files are
    /// untouched if extraction fails; otherwise extraction fails on them.
    public func unzipFile(_ zipFile: URL, destination: URL, overwrite: Bool) throws {
        let fileManager = FileManager.default
        if overwrite {
            try replaceItems(with: zipFile, in: destination, fileManager: fileManager)
        } else {
            try fileManager.unzipItem(at: zipFile, to: destination)
        }
    }

    // MARK: Private

    /// Extracts into a staging directory on the same volume, then swaps each entry into `destination`,
    /// so readers never find a replaced file missing.
    private func replaceItems(with zipFile: URL, in destination: URL, fileManager: FileManager) throws {
        let archive = try Archive(url: zipFile, accessMode: .read)
        // Validate every entry before changing anything, so a crafted archive cannot replace files outside `destination`.
        let entries = try archive.map { entry in
            (target: try containedURL(for: entry.path, in: destination), path: entry.path, isDirectory: entry.type == .directory)
        }

        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        let staging = try fileManager.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: destination, create: true)
        defer { try? fileManager.removeItem(at: staging) }
        try fileManager.unzipItem(at: zipFile, to: staging)

        for entry in entries {
            if entry.isDirectory {
                try fileManager.createDirectory(at: entry.target, withIntermediateDirectories: true)
                continue
            }
            let extracted = staging.appendingPathComponent(entry.path)
            if (try? entry.target.checkResourceIsReachable()) == true {
                _ = try fileManager.replaceItemAt(entry.target, withItemAt: extracted)
            } else {
                try fileManager.createDirectory(at: entry.target.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fileManager.moveItem(at: extracted, to: entry.target)
            }
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
