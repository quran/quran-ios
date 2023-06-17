//
//  Timing.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import Foundation

public struct Timing {
    // MARK: Lifecycle

    public init(time: Int) {
        self.time = time
    }

    // MARK: Public

    public var seconds: Double {
        Double(time) / 1000
    }

    // MARK: Internal

    let time: Int
}
