//
//  SystemTimeFake.swift
//
//
//  Created by Mohamed Afifi on 2023-05-07.
//

import Foundation
import SystemDependencies

public final class SystemTimeFake: SystemTime {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    public var now = Date(timeIntervalSinceReferenceDate: 0)
}
