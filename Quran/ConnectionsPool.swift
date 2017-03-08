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

    var pool: [String: (uses: Int, connection: Connection)] = [:]

    func getConnection(filePath: String) throws -> Connection {
        if let (uses, connection) = pool[filePath] {
            pool[filePath] = (uses + 1, connection)
            return connection
        } else {
            do {
                try? FileManager.default.createDirectory(atPath: filePath.stringByDeletingLastPathComponent,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
                let connection = try Connection(filePath, readonly: false)
                connection.busyTimeout = 2

                connection.busyHandler { tries in tries < 3 }
                pool[filePath] = (1, connection)
                return connection
            } catch {
                Crash.recordError(error, reason: "Cannot open connection to sqlite file '\(filePath)'.")
                throw PersistenceError.openDatabase(error)
            }
        }
    }

    func close(connection: Connection) {
        let filePath = String(cString: sqlite3_db_filename(connection.handle, nil))
        if let (uses, connection) = pool[filePath] {
            if uses <= 1 {
                pool[filePath] = nil // remove it
            } else {
                pool[filePath] = (uses - 1, connection)
            }
        } else {
            CLog("Warning: Closing connection multiple times '\(filePath)'")
        }
    }
}
