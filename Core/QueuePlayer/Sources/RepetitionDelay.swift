//
//  RepetitionDelay.swift
//  QueuePlayer
//

public enum RepetitionDelay: Int, Hashable, Sendable, CaseIterable, Comparable {
    case none
    case oneSecond
    case twoSeconds
    case threeSeconds
    case fiveSeconds
    case tenSeconds

    // MARK: Public

    public var seconds: Double {
        switch self {
        case .none: return 0
        case .oneSecond: return 1
        case .twoSeconds: return 2
        case .threeSeconds: return 3
        case .fiveSeconds: return 5
        case .tenSeconds: return 10
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.seconds == rhs.seconds {
            return lhs.rawValue < rhs.rawValue
        }

        return lhs.seconds < rhs.seconds
    }
}
