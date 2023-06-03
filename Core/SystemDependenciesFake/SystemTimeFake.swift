//
//  SystemTimeFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
import SystemDependencies

public final class SystemTimeFake: SystemTime {
    public var now = Date(timeIntervalSinceReferenceDate: 0)

    public init() {}
}
