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

    public static let sortedReadings: [Reading] = [
        .hafs_1405, .tajweed, .hafs_1421, .hafs_1440,
    ]

    public var quran: Quran {
        switch self {
        case .hafs_1405:
            return .hafsMadani1405
        case .hafs_1440:
            return .hafsMadani1440
        case .hafs_1421:
            return .hafsMadani1440
        case .tajweed:
            return .hafsMadani1405
        }
    }
}
