//
//  Crasher.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/28/17.
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
import Locking

public class CrasherKeyBase {}

public final class CrasherKey<Type>: CrasherKeyBase {
    public let key: String
    public init(key: String) {
        self.key = key
    }
}

public protocol CrashInfoHandler {
    func setValue<T>(_ value: T?, forKey key: CrasherKey<T>)
    func recordError(_ error: Error, reason: String, file: StaticString, line: UInt)
}

private struct NoOpCrashInfoHandler: CrashInfoHandler {
    func setValue<T>(_ value: T?, forKey key: CrasherKey<T>) {
        print("[NoOpCrashInfoHandler] setValue called. Don't use NoOpCrashInfoHandler in production")
    }

    func recordError(_ error: Error, reason: String, file: StaticString, line: UInt) {
        print("[NoOpCrashInfoHandler] recordError called. Don't use NoOpCrashInfoHandler in production")
    }
}

public enum CrashInfoSystem {
    private static let lock = NSLock()
    private(set) static var factory: (() -> CrashInfoHandler) = NoOpCrashInfoHandler.init
    private static var initialized = false

    public static func bootstrap(_ factory: @escaping () -> CrashInfoHandler) {
        lock.sync {
            precondition(!initialized, "CrashInfoSystem can only be initialized once.")
            self.factory = factory
            initialized = true
        }
    }
}

public struct Crasher {
    public let handler: CrashInfoHandler
    public init() {
        handler = CrashInfoSystem.factory()
    }

    public func recordError(_ error: Error, reason: String, file: StaticString = #file, line: UInt = #line) {
        handler.recordError(error, reason: reason, file: file, line: line)
    }

    public func setValue<T>(_ value: T?, forKey key: CrasherKey<T>) {
        handler.setValue(value, forKey: key)
    }
}
