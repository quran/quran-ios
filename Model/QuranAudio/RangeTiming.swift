//
//  RangeTiming.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import QuranKit

public struct RangeTiming {
    // MARK: Lifecycle

    public init(timings: [Sura: SuraTiming], endTime: Timing?) {
        self.timings = timings
        self.endTime = endTime
    }

    // MARK: Public

    public let timings: [Sura: SuraTiming]
    public let endTime: Timing?
}
