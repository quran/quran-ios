//
//  SqlitePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

protocol SqlitePersistence {
    var filePath: String { get }
    var version: UInt { get }

    func onCreate(connection: Connection) throws
    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws
}

extension SqlitePersistence {

    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws {
        // default implementation
    }

    func openConnection() -> Connection {
        // create the connection
        let connection = ConnectionsPool.default.getConnection(filePath: filePath)
        let oldVersion = connection.userVersion
        let newVersion = version
        precondition(newVersion != 0, "version should be greater than 0.")

        // if first time
        if oldVersion <= 0 {
            do {
                try onCreate(connection: connection)
                connection.userVersion = Int(newVersion)
            } catch {
                Crash.recordError(error)
                fatalError("Cannot create database for file '\(filePath)'", error)
            }
        } else {
            let unsignedOldVersion = UInt(oldVersion)
            if newVersion != unsignedOldVersion {
                do {
                    try onUpgrade(connection: connection, oldVersion: unsignedOldVersion, newVersion: newVersion)
                    connection.userVersion = Int(newVersion)
                } catch {
                    Crash.recordError(error)
                    fatalError("Cannot upgrade database for file '\(filePath)' from \(unsignedOldVersion) to \(newVersion)", error)
                }
            }
        }
        return connection
    }

    func run<T>(_ block: (Connection) throws -> T) -> T {
        let connection = openConnection()
        defer {
            ConnectionsPool.default.close(connection: connection)
        }
        do {
            return try block(connection)
        } catch {
            Crash.recordError(error)
            fatalError("Error while executing sqlite statement", error)
        }
    }
}
