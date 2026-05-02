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
    static var sorted: [Runs] {
        [.one, .two, .three, .four, .five, .indefinite]
    }

    var localizedDescription: String {
        switch self {
        case .one, .two, .three, .four, .five: return NumberFormatter.shared.format(count) + "×"
        case .indefinite: return lAndroid("repeatValues[3]")
        }
    }

    private var count: Int {
        switch self {
        case .one: return 1
        case .two: return 2
        case .three: return 3
        case .four: return 4
        case .five: return 5
        case .indefinite: preconditionFailure("Indefinite runs do not have a finite count.")
        }
    }
}
