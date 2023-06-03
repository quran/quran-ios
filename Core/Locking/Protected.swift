//
//  Protected.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/16/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

public class Protected<T> {
    private var _data: T
    private let lock: NSLocking

    public init(_ data: T, using lock: NSLocking = NSLock()) {
        _data = data
        self.lock = lock
    }

    public var value: T {
        get {
            lock.sync {
                _data
            }
        }
        set {
            lock.sync {
                _data = newValue
            }
        }
    }

    public func sync<U>(_ body: (inout T) throws -> U) rethrows -> U {
        try lock.sync {
            var d = _data
            let result = try body(&d)
            _data = d
            return result
        }
    }

    public func sync(_ body: (inout T) throws -> Void) rethrows {
        try lock.sync {
            var d = _data
            try body(&d)
            _data = d
        }
    }
}
