//
//  RepetitionDelay++.swift
//  Quran
//

import Foundation
import Localization
import QueuePlayer

extension RepetitionDelay {
    static var sorted: [RepetitionDelay] {
        [.none, .oneSecond, .twoSeconds, .threeSeconds, .fiveSeconds, .tenSeconds]
    }

    var localizedDescription: String {
        switch self {
        case .none: return l("audio.repetition-delay.none")
        case .oneSecond: return l("audio.repetition-delay.1s")
        case .twoSeconds: return l("audio.repetition-delay.2s")
        case .threeSeconds: return l("audio.repetition-delay.3s")
        case .fiveSeconds: return l("audio.repetition-delay.5s")
        case .tenSeconds: return l("audio.repetition-delay.10s")
        }
    }
}
