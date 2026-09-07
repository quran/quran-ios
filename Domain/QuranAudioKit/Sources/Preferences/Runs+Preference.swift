//
//  Runs+Preference.swift
//
//
//  Created by Abdullah Levin on 2026-09-08.
//

import QueuePlayer

extension Runs {
    /// Endless repetition is stored as `0`, since a finite number of runs is always
    /// at least one. A stored value that is not a usable count reads back as endless.
    init(preferenceValue: Int) {
        self = preferenceValue > 0 ? .finite(preferenceValue) : .indefinite
    }

    var preferenceValue: Int {
        switch self {
        case .finite(let count): return max(count, 1)
        case .indefinite: return 0
        }
    }
}
