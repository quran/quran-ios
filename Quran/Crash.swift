//
//  Crash.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/10/16.
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

import Crashlytics

public class CrashlyticsKeyBase {}

extension CrasherKeyBase {
    static let QariId = CrasherKey<Int>(key: "QariId")
    static let QuranPage = CrasherKey<Int>(key: "QuranPage")
    static let PlayingAyah = CrasherKey<AyahNumber>(key: "PlayingAyah")
    static let DownloadingQuran = CrasherKey<Bool>(key: "DownloadingQuran")
}

struct CrashlyticsCrasher: Crasher {

    let tag: StaticString = "Quran"
    let localizedUnkownError: String = NSLocalizedString("unknown_error_message", comment: "")

    func setValue<T>(_ value: T?, forKey key: CrasherKey<T>) {

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

    func recordError(_ error: Error, reason: String, fatalErrorOnDebug: Bool = true, file: StaticString = #file, line: UInt = #line) {
        CLog("Error Occurred, reason: \(reason), error: \(type(of: error)): \(error)")
        Crashlytics.sharedInstance().recordError(error as NSError, withAdditionalUserInfo: ["quran.reason": reason])
        #if DEBUG
            if fatalErrorOnDebug {
                fatalError(reason, error, file: file, line: line)
            }
        #endif
    }

    func log(_ message: String) {
        CLSLogv("%@", getVaList([message]))
    }
}

public func fatalError(_ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    VFoundation.fatalError(message, file: file, line: line)
}

public func fatalError(_ message: @autoclosure () -> String = "", _ error: Error, file: StaticString = #file, line: UInt = #line) -> Never {
    VFoundation.fatalError(message, error, file: file, line: line)
}
