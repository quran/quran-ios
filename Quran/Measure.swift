//
//  Measure.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
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

import Foundation

func measure<T>(_ tag: String = #function, limit: TimeInterval = 0, _ body: () throws -> T) rethrows -> T {

    let start = DispatchTime.now() // <<<<<<<<<< Start time
    let result = try body()
    let end = DispatchTime.now()   // <<<<<<<<<<   end time
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

    if timeInterval >= limit {
        print("[\(tag)]: Time Elabsed \(timeInterval) seconds")
    }

    return result
}
