//
//  Reading.swift
//
//
//  Created by Mohamed Afifi on 2023-02-14.
//

public enum Reading: Int {
    case hafs_1405 = 0
    case hafs_1440 = 1
    case tajweed = 2
    case hafs_1421 = 3
    case hafs_1441 = 4

    // MARK: Public

    public static let allReadings: [Reading] = [
        .hafs_1405, .tajweed, .hafs_1421, .hafs_1440, .hafs_1441,
    ]

    public static let sortedReadings: [Reading] = allReadings

    public var quran: Quran {
        switch self {
        case .hafs_1405:
            return .hafsMadani1405
        case .hafs_1440:
            return .hafsMadani1440
        case .hafs_1421:
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
        case .hafs_1441:
            return 1440
        default:
            return nil
        }
    }
}
