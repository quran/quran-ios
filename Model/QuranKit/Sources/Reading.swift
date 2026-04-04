//
//  Reading.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

import Foundation

public enum Reading: Int {
    case hafs_1405 = 0
    case hafs_1440 = 1
    case tajweed = 2
    case hafs_1421 = 3
    case hafs_1441 = 4
    case hafs_1439 = 5

    // MARK: Public

    public static let allReadings: [Reading] = [
        .hafs_1405, .tajweed, .hafs_1421, .hafs_1440, .hafs_1439, .hafs_1441,
    ]

    public var quran: Quran {
        switch self {
        case .hafs_1405:
            return .hafsMadani1405
        case .hafs_1440:
            return .hafsMadani1440
        case .hafs_1421:
            return .hafsMadani1440
        case .hafs_1439:
            return .hafsMadani1440
        case .hafs_1441:
            return .hafsMadani1440
        case .tajweed:
            return .hafsMadani1405
        }
    }

    public var usesLinePages: Bool {
        linePageAssetWidth != nil
    }

    public var linePageAssetWidth: Int? {
        switch self {
        case .hafs_1439:
            return 1080
        case .hafs_1441:
            return 1440
        default:
            return nil
        }
    }

    public var imageAssetWidth: Int {
        switch self {
        case .hafs_1405:
            return 1920
        case .hafs_1421:
            return 1120
        case .hafs_1440:
            return 1352
        case .hafs_1439:
            return 1080
        case .hafs_1441:
            return 1440
        case .tajweed:
            return 1280
        }
    }

    public var usesBlueLinePageChrome: Bool {
        self == .hafs_1439
    }

    public var usesInvertedQuranImageRenderingInDarkMode: Bool {
        switch self {
        case .hafs_1440, .hafs_1439, .hafs_1441, .tajweed:
            return true
        case .hafs_1405, .hafs_1421:
            return false
        }
    }

    public func ayahInfoDatabase(in directory: URL) -> URL {
        let width = imageAssetWidth
        return directory
            .appendingPathComponent("images_\(width)")
            .appendingPathComponent("databases")
            .appendingPathComponent("ayahinfo_\(width).db")
    }

    public func imagesDirectory(in directory: URL) -> URL {
        let width = imageAssetWidth
        return directory
            .appendingPathComponent("images_\(width)")
            .appendingPathComponent("width_\(width)")
    }
}
