//
//  Runs++.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/26/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import QueuePlayer

extension Runs {
    static var sorted: [Runs] {
        [.one, .two, .three, .indefinite]
    }

    var localizedDescription: String {
        switch self {
        case .one: return lAndroid("repeatValues[0]")
        case .two: return lAndroid("repeatValues[1]")
        case .three: return lAndroid("repeatValues[2]")
        case .four: fatalError("Not implemented")
        case .indefinite: return lAndroid("repeatValues[3]")
        }
    }
}
