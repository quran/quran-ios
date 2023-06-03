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
    public init() { }

    public var now: Date {
        Date()
    }
}
