//
//  RepetitionDelay++.swift
//  Quran
//

import Foundation
import Localization
import QueuePlayer

extension RepetitionDelay {
    static var sorted: [RepetitionDelay] {
        RepetitionDelay.allCases.sorted()
    }

    var localizedDescription: String {
        switch self {
        case .none: return l("audio.delay.off")
        case .oneSecond: return l("audio.repetition-delay.1s")
        case .twoSeconds: return l("audio.repetition-delay.2s")
        case .threeSeconds: return l("audio.repetition-delay.3s")
        case .fiveSeconds: return l("audio.repetition-delay.5s")
        case .tenSeconds: return l("audio.repetition-delay.10s")
        }
    }
}
