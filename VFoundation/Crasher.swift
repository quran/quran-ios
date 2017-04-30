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

public class CrasherKeyBase {}

public final class CrasherKey<Type>: CrasherKeyBase {
    public let key: String
    public init(key: String) {
        self.key = key
    }
}

public protocol Crasher {
    var tag: StaticString { get }

    func setValue<T>(_ value: T?, forKey key: CrasherKey<T>)
    func recordError(_ error: Error, reason: String, fatalErrorOnDebug: Bool, file: StaticString, line: UInt)
    func log(_ message: String)
    func logCriticalIssue(_ message: String)

    var localizedUnkownError: String { get }
}

public struct Crash {
    // should be set at the very begining of the app.
    public static var crasher: Crasher?

    public static func recordError(_ error: Error, reason: String, fatalErrorOnDebug: Bool = true, file: StaticString = #file, line: UInt = #line) {
        Crash.crasher?.recordError(error, reason: reason, fatalErrorOnDebug: fatalErrorOnDebug, file: file, line: line)
    }
    public static func setValue<T>(_ value: T?, forKey key: CrasherKey<T>) {
        Crash.crasher?.setValue(value, forKey: key)
    }
}

public func CLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let message = "[\(Crash.crasher?.tag ?? "_")]: " + items.map { "\($0)" }.joined(separator: separator) + terminator
    NSLog(message)
    Crash.crasher?.log(message)
}

public func logCriticalIssue(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let message = "[\(Crash.crasher?.tag ?? "_")]: " + items.map { "\($0)" }.joined(separator: separator) + terminator
    Crash.crasher?.logCriticalIssue(message)
}

public func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    CLog("message: \(message()), file:\(file.description), line:\(line)")
    Swift.fatalError(message, file: file, line: line)
}

public func fatalError(_ message: @autoclosure () -> String = "", _ error: Error, file: StaticString = #file, line: UInt = #line) -> Never {
    let fullMessage = "\(message()), error: \(error)"
    CLog("message: \(fullMessage), file:\(file.description), line:\(line)")
    Swift.fatalError(fullMessage, file: file, line: line)
}

