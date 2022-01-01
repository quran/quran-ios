//
//  ConnectionsPool.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/30/16.
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
import VLogging

final class ConnectionsPool {
    static var `default`: ConnectionsPool = ConnectionsPool()

    func getConnection(filePath: String) throws -> Connection {
        do {
            try? FileManager.default.createDirectory(atPath: filePath.stringByDeletingLastPathComponent,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
            let connection = try Connection(filePath, readonly: false)
            // wait for max of 5 seconds if the db is locked.
            // should be enough for most of the cases.
            connection.busyTimeout = 5
            return connection
        } catch {
            logger.error("Cannot open sqlite file \(filePath). Error: \(error)")
            throw PersistenceError.openDatabase(error, filePath: filePath)
        }
    }

    func close(connection: Connection) {
        // does nothing connection will be closed on dealloc
    }
}

extension Connection {
    public func setUserVersion(_ newValue: Int) throws {
        do {
            try run("PRAGMA user_version = \(newValue)")
        } catch {
            logger.error("Cannot set user_version to \(newValue). Error: \(error)")
            throw PersistenceError.generalError(error, info: "Cannot set value for user_version to \(newValue)")
        }
    }

    public func getUserVersion() throws -> Int {
        do {
            let value = try scalar("PRAGMA user_version")
            guard let version: Int64 = value as? Int64 else {
                logger.error("user_version is returned with unexpected type \(type(of: value)).")
                fatalError("user_version is returned with unexpected type \(type(of: value)).")
            }
            return Int(version)
        } catch {
            logger.error("Cannot get value for user_version. Error: \(error)")
            throw PersistenceError.generalError(error, info: "Cannot get value for user_version")
        }
    }
}
