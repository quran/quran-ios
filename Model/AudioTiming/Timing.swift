//
//  Timing.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import Foundation

public struct Timing {
    let time: Int

    public init(time: Int) {
        self.time = time
    }

    public var seconds: Double {
        Double(time) / 1000
    }
}
