//
//  AyahTiming.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
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

import QuranKit

public struct Timing {
    let time: Int

    public init(time: Int) {
        self.time = time
    }

    public var seconds: Double {
        Double(time) / 1000
    }
}

public struct AyahTiming {
    public let ayah: AyahNumber
    public let time: Timing

    public init(ayah: AyahNumber, time: Timing) {
        self.ayah = ayah
        self.time = time
    }
}

public struct SuraTiming {
    public let verses: [AyahTiming]
    public let endTime: Timing?

    public init(verses: [AyahTiming], endTime: Timing?) {
        self.verses = verses
        self.endTime = endTime
    }
}
