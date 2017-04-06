//
//  SQLitePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

protocol ReadonlySQLitePersistence {
    var filePath: String { get }
    func openConnection() throws -> Connection
}

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
        } catch {
            Crash.recordError(error, reason: "Error while executing sqlite statement")
            throw PersistenceError.query(error)
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
