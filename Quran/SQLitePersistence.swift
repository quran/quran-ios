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

import Foundation
import SQLite

protocol ReadonlySQLitePersistence {
    var filePath: String { get }
    func openConnection() throws -> Connection
}

private var dbFileIssueCodes: Set<Int32> = {
    return Set([SQLITE_PERM, SQLITE_NOTADB, SQLITE_CORRUPT, SQLITE_CANTOPEN])
}()

extension ReadonlySQLitePersistence {

    func openConnection() throws -> Connection {
        // create the connection
        let connection = try ConnectionsPool.default.getConnection(filePath: filePath)
        return connection
    }

    func run<T>(_ block: (Connection) throws -> T) throws -> T {
        do {
            let connection = try openConnection()
            defer {
                ConnectionsPool.default.close(connection: connection)
            }
            return try block(connection)
        } catch let error as PersistenceError {
            Crash.recordError(error, reason: "Error while executing sqlite statement")
            throw error

        } catch let error as SQLite.Result {
            switch error {
            case .error(message: _, code: let code, statement: _):
                if dbFileIssueCodes.contains(code) {
                    // remove the db file as sometimes, the download is completed with error.
                    if let url = URL(string: filePath) {
                        try? FileManager.default.removeItem(at: url)
                    }
                    throw PersistenceError.badFile(error)
                }
            }
            Crash.recordError(error, reason: "Error while executing sqlite statement")
            throw PersistenceError.query(error)
        } catch {
            Crash.recordError(error, reason: "Error while executing sqlite statement")
            throw PersistenceError.query(error)
        }
    }
}

extension ReadonlySQLitePersistence {
    func validateFileExists() throws {
        if let url = URL(string: filePath) {
            if !url.isReachable {
                throw PersistenceError.badFile(nil)
            }
        }
    }
}

protocol SQLitePersistence: ReadonlySQLitePersistence {
    var filePath: String { get }
    var version: UInt { get }

    func onCreate(connection: Connection) throws
    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws
}

extension SQLitePersistence {

    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws {
        // default implementation
    }

    func openConnection() throws -> Connection {
        // create the connection
        let connection = try ConnectionsPool.default.getConnection(filePath: filePath)
        let oldVersion = connection.userVersion
        let newVersion = version
        precondition(newVersion != 0, "version should be greater than 0.")

        // if first time
        if oldVersion <= 0 {
            do {
                try onCreate(connection: connection)
                connection.userVersion = Int(newVersion)
            } catch {
                Crash.recordError(error, reason: "Cannot create database for file '\(filePath)'")
                throw PersistenceError.query(error)
            }
        } else {
            let unsignedOldVersion = UInt(oldVersion)
            if newVersion != unsignedOldVersion {
                do {
                    try onUpgrade(connection: connection, oldVersion: unsignedOldVersion, newVersion: newVersion)
                    connection.userVersion = Int(newVersion)
                } catch {
                    Crash.recordError(error, reason: "Cannot upgrade database for file '\(filePath)' from \(unsignedOldVersion) to \(newVersion)")
                    throw PersistenceError.query(error)
                }
            }
        }
        return connection
    }
}
