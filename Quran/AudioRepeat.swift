//
//  AudioRepeat.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

enum AudioRepeat {
    case None
    case Once
    case Twice
    case ThreeTimes
    case Infinite

    func next() -> AudioRepeat {
        switch  self {
        case .None:
            return .Once
        case .Once:
            return .Twice
        case .Twice:
            return .ThreeTimes
        case .ThreeTimes:
            return .Infinite
        case .Infinite:
            return .None
        }
    }
}
