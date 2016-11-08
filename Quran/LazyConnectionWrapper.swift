//
//  LazyConnectionWrapper.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
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

class LazyConnectionWrapper {

    let sqliteFilePath: String
    let readonly: Bool

    init(sqliteFilePath: String, readonly: Bool = false) {
        self.sqliteFilePath = sqliteFilePath
        self.readonly = readonly
    }

    var instance: Connection?

    func getOpenConnection() throws -> Connection {
        if let connection = instance {
            return connection
        }
        do {
            let connection = try Connection(sqliteFilePath, readonly: readonly)
            instance = connection
            return connection
        } catch {
            Crash.recordError(error, reason: "Cannot open connection to sqlite file '\(sqliteFilePath)'")
            throw PersistenceError.openDatabase(error: error)
        }
    }
}
