//
//  ReadonlySQLitePersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/17.
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

public protocol ReadonlySQLitePersistence {
    var filePath: String { get }
    func openConnection() throws -> Connection
}

private var dbFileIssueCodes: Set<Int32> = {
    return Set([SQLITE_PERM, SQLITE_NOTADB, SQLITE_CORRUPT, SQLITE_CANTOPEN])
}()

extension ReadonlySQLitePersistence {

    public func openConnection() throws -> Connection {
        // create the connection
        let connection = try ConnectionsPool.default.getConnection(filePath: filePath)
        return connection
    }

    public func run<T>(using external: Connection? = nil, _ block: (Connection) throws -> T) throws -> T {
        do {
            // open the connection
            let connection: Connection
            if let external = external {
                connection = external
            } else {
                connection = try openConnection()

                // close the connection
                defer {
                    ConnectionsPool.default.close(connection: connection)
                }
            }

            // execute the query
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
    public func validateFileExists() throws {
        if let url = URL(string: filePath) {
            if !url.isReachable {
                throw PersistenceError.badFile(nil)
            }
        }
    }
}
