//
//  SQLite+Extension.swift
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

import SQLite

extension Connection {
    public var userVersion: Int {
        get {
            do {
                let version: Int64 = cast(try scalar("PRAGMA user_version"))
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
