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

    func openConnection() -> Connection
    func onCreate(connection: Connection) throws
    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws
}

extension SqlitePersistence {

    private func createConnection() -> LazyConnectionWrapper {
        return LazyConnectionWrapper(sqliteFilePath: filePath, readonly: false)
    }

    func onUpgrade(connection: Connection, oldVersion: UInt, newVersion: UInt) throws {
        // default implementation
    }

    func openConnection() -> Connection {
        // create the connection
        let connection = createConnection().connection
        let oldVersion = connection.userVersion
        let newVersion = version

        // if first time
        if oldVersion <= 0 {
            do {
                try onCreate(connection: connection)
            } catch {
                Crash.recordError(error)
                fatalError("Cannot create database for file '\(filePath)'", error)
            }
        } else {
            let unsignedOldVersion = UInt(oldVersion)
            if newVersion != unsignedOldVersion {
                do {
                    try onUpgrade(connection: connection, oldVersion: unsignedOldVersion, newVersion: newVersion)
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
        do {
            return try block(connection)
        } catch {
            Crash.recordError(error)
            fatalError("Error while executing sqlite statement", error)
        }
    }
}
