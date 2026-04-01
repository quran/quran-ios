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

    public static let sortedReadings: [Reading] = {
        var readings: [Reading] = [
            .hafs_1405, .tajweed, .hafs_1421, .hafs_1440,
        ]
        if is1441Visible {
            readings.append(.hafs_1441)
        }
        return readings
    }()

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

    // MARK: Private

    // Keep 1441 hidden until the end-to-end line-page flow is ready.
    private static let is1441Visible = false
}
