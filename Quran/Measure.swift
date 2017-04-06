//
//  Measure.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/1/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

func measure(_ tag: String = #function, limit: TimeInterval = 0, _ body: () -> Void) {

    let start = DispatchTime.now() // <<<<<<<<<< Start time
    body()
    let end = DispatchTime.now()   // <<<<<<<<<<   end time
    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds // <<<<< Difference in nano seconds (UInt64)
    let timeInterval = Double(nanoTime) / 1_000_000_000 // Technically could overflow for long running tests

    if timeInterval >= limit {
        print("[\(tag)]: Time Elabsed \(timeInterval) seconds")
    }
}
