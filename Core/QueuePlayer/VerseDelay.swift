//
//  VerseDelay.swift
//  QueuePlayer
//
//  Created by Abdirizak Hassan on 6/5/26.
//  Copyright © 2026 Abdirizak Hassan. All rights reserved.
//

/// A delay inserted between verse playbacks, expressed as a multiplier of the
/// duration of the verse that was just recited.
///
/// e.g. if a verse took 8 seconds to recite and `.half` (0.5×) is selected, the
/// player waits 4 seconds before starting the next verse. The delay is applied
/// between every verse, including repeated playbacks of the same verse.
// NOTE: Raw values are persisted in preferences, so only ever append new cases
// at the end — never reorder or renumber existing ones. Cases are declared in
// ascending multiplier order for readability, but display sorting should use
// `Comparable` so future appended cases can still appear in multiplier order.
public enum VerseDelay: Int, Hashable, Sendable, CaseIterable, Comparable {
    case none
    case quarter
    case half
    case threeQuarters
    case full
    case oneAndQuarter
    case oneAndHalf
    case oneAndThreeQuarters
    case double

    // MARK: Public

    /// The multiplier applied to the recited verse's duration to get the delay.
    public var multiplier: Double {
        switch self {
        case .none: return 0
        case .quarter: return 0.25
        case .half: return 0.5
        case .threeQuarters: return 0.75
        case .full: return 1
        case .oneAndQuarter: return 1.25
        case .oneAndHalf: return 1.5
        case .oneAndThreeQuarters: return 1.75
        case .double: return 2
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.multiplier == rhs.multiplier {
            return lhs.rawValue < rhs.rawValue
        }

        return lhs.multiplier < rhs.multiplier
    }
}
