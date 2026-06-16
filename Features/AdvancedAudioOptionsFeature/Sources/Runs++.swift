//
//  Runs++.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import Localization
import QueuePlayer

extension Runs {
    var localizedDescription: String {
        switch self {
        case .finite(let count): return NumberFormatter.shared.format(count) + "×"
        case .indefinite: return lAndroid("repeatValues[3]")
        }
    }
}
