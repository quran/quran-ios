//
//  VerseDelay++.swift
//  Quran
//
//  Created by Abdirizak Hassan on 6/5/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Foundation
import Localization
import QueuePlayer

extension VerseDelay {
    static var sorted: [VerseDelay] {
        VerseDelay.allCases.sorted()
    }

    var localizedDescription: String {
        switch self {
        case .none:
            return l("audio.delay.off")
        default:
            return Self.multiplierFormatter.format(multiplier) + "×"
        }
    }

    // MARK: Private

    private static let multiplierFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = NumberFormatter.shared.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
}
