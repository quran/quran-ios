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

import Foundation
import SQLite
import SQLite3
import Utilities
import VLogging

public protocol ReadonlySQLitePersistence {
    var filePath: String { get }
    func openConnection() throws -> Connection
}

private var dbFileIssueCodes: Set<Int32> = {
    Set([SQLITE_PERM, SQLITE_NOTADB, SQLITE_CORRUPT, SQLITE_CANTOPEN])
}()

extension ReadonlySQLitePersistence {
    public func openConnection() throws -> Connection {
        // create the connection
        let connection = try ConnectionsPool.default.getConnection(filePath: filePath)
        return connection
    }

    public func run<T>(using external: Connection? = nil, inTransaction: Bool = false, _ block: (Connection) throws -> T) throws -> T {
        do {
            // open the connection
            let connection: Connection
            if let external {
                connection = external
            } else {
                connection = try openConnection()

                // close the connection
                do {
                    ConnectionsPool.default.close(connection: connection)
                }
            }

            return try attempt(times: 3) {
                if inTransaction {
                    var result: T?
                    try connection.transaction {
                        result = try block(connection)
                    }

                    return result!
                } else {
                    // execute the query
                    return try block(connection)
                }
            }

        } catch let error as PersistenceError {
            throw error // re-throw

        } catch let error as SQLite.Result {
            switch error {
            case .error(message: _, code: let code, statement: _):
                if dbFileIssueCodes.contains(code) {
                    // remove the db file as sometimes, the download is completed with error.
                    if let url = URL(string: filePath) {
                        try? FileManager.default.removeItem(at: url)
                    }
                    logger.error("Bad file error while executing query. Error: \(error).")
                    throw PersistenceError.badFile(error)
                }
            }
            throw PersistenceError.query(error)
        } catch {
            logger.error("General error while executing query. Error: \(error).")
            throw PersistenceError.query(error)
        }
    }
}

extension ReadonlySQLitePersistence {
    public func validateFileExists() throws {
        guard !FileManager.default.fileExists(atPath: filePath) else {
            return
        }
        if let url = URL(string: filePath) {
            if !url.isReachable {
                logger.error("File is unreachable. File: \(filePath).")
                throw PersistenceError.badFile(nil)
            }
        }
    }
}
