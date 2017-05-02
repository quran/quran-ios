//
//  SQLitePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
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
import VFoundation

public protocol SQLitePersistence: ReadonlySQLitePersistence {
    var filePath: String { get }
    var version: UInt { get }

    func onCreate(connection: Connection) throws
    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws
}

extension SQLitePersistence {

    public func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws {
        // default implementation
    }

    public func openConnection() throws -> Connection {
        // create the connection
        let connection = try ConnectionsPool.default.getConnection(filePath: filePath)
        let oldVersion = try connection.getUserVersion()
        let newVersion = version
        precondition(newVersion != 0, "version should be greater than 0.")

        // if first time
        if oldVersion <= 0 {
            try connection.transaction {
                do {
                    try onCreate(connection: connection)
                } catch {
                    throw PersistenceError.generalError(error, info: "Cannot create database for file '\(filePath)'")
                }
                try connection.setUserVersion(Int(newVersion))
            }
        } else {
            let unsignedOldVersion = UInt(oldVersion)
            if newVersion != unsignedOldVersion {
                try connection.transaction {
                    do {
                        try onUpgrade(connection: connection, oldVersion: unsignedOldVersion, newVersion: newVersion)
                    } catch {
                        throw PersistenceError.generalError(
                            error, info: "Cannot upgrade database for file '\(filePath)' from \(unsignedOldVersion) to \(newVersion)")
                    }
                    try connection.setUserVersion(Int(newVersion))
                }
            }
        }
        return connection
    }
}
