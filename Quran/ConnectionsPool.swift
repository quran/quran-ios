//
//  ConnectionsPool.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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
            connection.busyTimeout = 3
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
