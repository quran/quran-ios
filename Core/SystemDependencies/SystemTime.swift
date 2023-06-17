//
//  SystemTime.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation

public protocol SystemTime {
    var now: Date { get }
}

public struct DefaultSystemTime: SystemTime {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var now: Date {
        Date()
    }
}
