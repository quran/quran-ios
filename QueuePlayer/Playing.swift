//
//  Playing.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-04.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import AVFoundation

struct Playing {
    let item: AVPlayerItem
    let time: Int
    private (set) var plays: Int {
        didSet {
            lastUpdated = Date()
        }
    }
    private (set) var lastUpdated: Date = Date()

    var recentlyUpdated: Bool {
        return abs(lastUpdated.timeIntervalSinceNow) < 0.5
    }

    mutating func increment() {
        plays.increment()
    }

    init(item: AVPlayerItem, time: Int) {
        self.item = item
        self.time = time
        self.plays = 0
        self.lastUpdated = Date()
    }
}

extension Int {
    mutating func increment() {
        // prevent overflow due to indefinite Runs
        guard self != Int.max else {
            return
        }
        self += 1
    }
}
