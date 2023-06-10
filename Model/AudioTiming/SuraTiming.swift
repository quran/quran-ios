//
//  SuraTiming.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

public struct SuraTiming {
    public let verses: [AyahTiming]
    public let endTime: Timing?

    public init(verses: [AyahTiming], endTime: Timing?) {
        self.verses = verses
        self.endTime = endTime
    }
}
