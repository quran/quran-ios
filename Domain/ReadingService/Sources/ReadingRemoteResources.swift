//
//  ReadingRemoteResources.swift
//
//
//  Created by Mohamed Afifi on 2023-11-20.
//

import Foundation
import QuranKit
import SystemDependencies
import Utilities

public protocol ReadingRemoteResources {
    func resource(for reading: Reading) -> RemoteResource?
}

public struct RemoteResource {
    // MARK: Lifecycle

    public init(url: URL, reading: Reading, version: Int) {
        self.url = url
        self.reading = reading
        self.version = version
        downloadDestination = Reading.readingsPath.appendingPathComponent(reading.localPath, isDirectory: true)
    }

    // MARK: Public

    public let downloadDestination: RelativeFilePath

    public func isDownloaded(fileSystem: FileSystem = DefaultFileSystem()) -> Bool {
        if hasSuccessFile(fileSystem: fileSystem) {
            return true
        }
        return canRecoverSuccessFile(fileSystem: fileSystem)
    }

    // MARK: Internal

    let url: URL
    let reading: Reading
    let version: Int

    var zipFile: RelativeFilePath {
        downloadDestination.appendingPathComponent(url.lastPathComponent, isDirectory: false)
    }

    var successFilePath: RelativeFilePath {
        downloadDestination.appendingPathComponent("success-v\(version).txt", isDirectory: false)
    }

    var extractedVersionFileURL: URL {
        reading.imagesDirectory(in: downloadDestination.url)
            .appendingPathComponent(".v\(version)")
    }

    func hasSuccessFile(fileSystem: FileSystem = DefaultFileSystem()) -> Bool {
        fileSystem.fileExists(at: successFilePath)
    }

    func canRecoverSuccessFile(fileSystem: FileSystem = DefaultFileSystem()) -> Bool {
        // The CDN can serve a newer dataset under the same URL before the app
        // updates its bundled version number. A matching .vN marker tells us
        // that newer dataset landed, and any older success-vK.txt confirms a
        // prior unzip completed successfully on this device.
        guard fileSystem.fileExists(at: extractedVersionFileURL) else {
            return false
        }
        return hasSuccessFile(forAnyVersionBefore: version, fileSystem: fileSystem)
    }

    // MARK: Private

    private func hasSuccessFile(forAnyVersionBefore version: Int, fileSystem: FileSystem) -> Bool {
        guard version > 1 else {
            return false
        }
        for previousVersion in 1 ..< version {
            if fileSystem.fileExists(at: successFilePath(for: previousVersion)) {
                return true
            }
        }
        return false
    }

    private func successFilePath(for version: Int) -> RelativeFilePath {
        downloadDestination.appendingPathComponent("success-v\(version).txt", isDirectory: false)
    }
}

private extension Reading {
    static let readingsPath = RelativeFilePath("readings", isDirectory: true)
}

extension Reading {
    public var localPath: String {
        switch self {
        case .hafs_1405: return "hafs_1405"
        case .hafs_1440: return "hafs_1440"
        case .hafs_1421: return "hafs_1421"
        case .hafs_1439: return "hafs_1439"
        case .hafs_1441: return "hafs_1441"
        case .tajweed: return "tajweed"
        case .naskh: return "naskh"
        }
    }

    static func isDownloadDesitnationPath(_ path: RelativeFilePath) -> Bool {
        readingsPath.isParent(of: path)
    }
}
