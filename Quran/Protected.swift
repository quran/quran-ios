//
//  Protected.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/16/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

public struct Protected<T> {
    private var _data: T
    private let lock = NSLock()

    init(_ data: T) {
        _data = data
    }

    public var value: T {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _data
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _data = newValue
        }
    }
}
