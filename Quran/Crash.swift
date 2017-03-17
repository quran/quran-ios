//
//  Crash.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/10/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import Crashlytics

class CrashlyticsKeyBase {
    static let QariId = CrashlyticsKey<Int>(key: "QariId")
    static let QuranPage = CrashlyticsKey<Int>(key: "QuranPage")
    static let PlayingAyah = CrashlyticsKey<AyahNumber>(key: "PlayingAyah")
    static let DownloadingQuran = CrashlyticsKey<Bool>(key: "DownloadingQuran")
}

final class CrashlyticsKey<Type>: CrashlyticsKeyBase {
    let key: String

    fileprivate init(key: String) {
        self.key = key
    }
}

struct Crash {

    static func setValue<T>(_ value: T?, forKey key: CrashlyticsKey<T>) {

        let instance = Crashlytics.sharedInstance()

        guard let value = value else {
            instance.setObjectValue(nil, forKey: key.key)
            return
        }

        if let value = value as? Int32 {
            instance.setIntValue(value, forKey: key.key)
        } else if let value = value as? Int {
            instance.setIntValue(Int32(value), forKey: key.key)
        } else if let value = value as? Float {
            instance.setFloatValue(value, forKey: key.key)
        } else if let value = value as? Bool {
            instance.setBoolValue(value, forKey: key.key)
        } else if let value = value as? CustomStringConvertible {
            instance.setObjectValue(value.description, forKey: key.key)
        } else {
            fatalError("Unsupported value type: \(value)")
        }
    }

    static func recordError(_ error: Error, reason: String, fatalErrorOnDebug: Bool = true) {
        CLog("Error Occurred, reason: \(reason), error: \(error)")
        Crashlytics.sharedInstance().recordError(error as NSError, withAdditionalUserInfo: ["quran.reason": reason])
        #if DEBUG
            if fatalErrorOnDebug {
                fatalError("\(reason). Error: \(error)")
            }
        #endif
    }
}

public func CLog(_ items: Any..., separator: String = " ", terminator: String = "\n") {
    let message = "[Quran]: " + items.map { "\($0)" }.joined(separator: separator) + terminator
    NSLog(message)
    CLSLogv("%@", getVaList([message]))
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

public func safely(_ from: String, _ body: () throws -> Void) {
    do {
        try body()
    } catch {
        Crash.recordError(error, reason: from)
    }
}
