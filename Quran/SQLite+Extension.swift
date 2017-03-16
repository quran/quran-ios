//
//  SQLite+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/16/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import SQLite

extension Connection {
    public var userVersion: Int {
        get {
            do {
                let version: Int64 = try scalar("PRAGMA user_version") as! Int64
                return Int(version)
            } catch {
                Crash.recordError(error, reason: "Cannot get value for user_version")
                fatalError("Cannot get user version from sqlite file. Error: '\(error)'")
            }
        }
        set {
            do {
                try run("PRAGMA user_version = \(newValue)")
            } catch {
                Crash.recordError(error, reason: "Cannot set value for user_version")
                fatalError("Cannot set user version to sqlite file. Error: '\(error)'")
            }
        }
    }
}
