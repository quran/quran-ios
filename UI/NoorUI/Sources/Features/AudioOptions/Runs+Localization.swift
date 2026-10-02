//
//  Runs+Localization.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import Localization
import QuranAudio

extension Runs {
    /// The repeat counts users pick from: Loop first, then 1× through 100×.
    static let choices: [Runs] = [.indefinite] + (1 ... 100).map(Runs.finite)

    var localizedDescription: String {
        switch self {
        case .finite(let count): return NumberFormatter.shared.format(count) + "×"
        case .indefinite: return lAndroid("repeatValues[3]")
        }
    }
}
