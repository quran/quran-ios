//
//  SuraTiming.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

public struct SuraTiming {
    // MARK: Lifecycle

    public init(verses: [AyahTiming], endTime: Timing?) {
        self.verses = verses
        self.endTime = endTime
    }

    // MARK: Public

    public let verses: [AyahTiming]
    public let endTime: Timing?
}
