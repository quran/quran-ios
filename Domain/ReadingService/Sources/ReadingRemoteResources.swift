//
//  ReadingRemoteResources.swift
//
//
//  Created by Mohamed Afifi on 2023-11-20.
//

import Foundation
import QuranKit
import Utilities

public protocol ReadingRemoteResources {
    func resource(for reading: Reading) -> RemoteResource?
}

public struct RemoteResource {
    // MARK: Lifecycle

    public init(url: URL, reading: Reading, version: Int) {
        self.url = url
        self.version = version
        downloadDestination = Reading.readingsPath.appendingPathComponent(reading.localPath, isDirectory: true)
    }

    // MARK: Public

    public let downloadDestination: RelativeFilePath

    // MARK: Internal

    let url: URL
    let version: Int

    var zipFile: RelativeFilePath {
        downloadDestination.appendingPathComponent(url.lastPathComponent, isDirectory: false)
    }

    var successFilePath: RelativeFilePath {
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
        case .tajweed: return "tajweed"
        }
    }

    static func isDownloadDesitnationPath(_ path: RelativeFilePath) -> Bool {
        readingsPath.isParent(of: path)
    }
}
