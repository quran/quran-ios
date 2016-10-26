//
//  AudioRepeat.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum AudioRepeat {
    case none
    case once
    case twice
    case threeTimes
    case infinite

    func next() -> AudioRepeat {
        switch  self {
        case .none:
            return .once
        case .once:
            return .twice
        case .twice:
            return .threeTimes
        case .threeTimes:
            return .infinite
        case .infinite:
            return .none
        }
    }
}
