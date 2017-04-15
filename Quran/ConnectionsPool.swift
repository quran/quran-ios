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
import CSQLite

final class ConnectionsPool {

    static var `default`: ConnectionsPool = ConnectionsPool()

    func getConnection(filePath: String) throws -> Connection {
        do {
            try? FileManager.default.createDirectory(atPath: filePath.stringByDeletingLastPathComponent,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
            let connection = try Connection(filePath, readonly: false)
            // wait for max of 3 seconds if the db is locked.
            // should be enough for most of the cases.
            connection.busyTimeout = 5
            return connection
        } catch {
            Crash.recordError(error, reason: "Cannot open connection to sqlite file '\(filePath)'.")
            throw PersistenceError.openDatabase(error)
        }
    }

    func close(connection: Connection) {
        // does nothing connection will be closed on dealloc
    }
}
