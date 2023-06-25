//
//  DatabaseConnection.swift
//
//
//  Created by Mohamed Afifi on 2023-05-25.
//

import Foundation
import GRDB
import Utilities
import VLogging

private struct DatabaseConnectionPool: Sendable {
    private struct Connection {
        let database: DatabaseWriter
        var references: Int
    }

    private struct State {
        var connections: [URL: Connection] = [:]
    }

    // MARK: Internal

    func database(for url: URL, readonly: Bool) throws -> DatabaseWriter {
        try state.withCriticalRegion { state in
            if var connection = state.connections[url] {
                connection.references += 1
                state.connections[url] = connection
                return connection.database
            }

            // Create the database folder if needed.
            try? FileManager.default.createDirectory(
                atPath: url.path.stringByDeletingLastPathComponent,
                withIntermediateDirectories: true,
                attributes: nil
            )

            let database = try newDatabase(url: url, readonly: readonly)
            let newConnection = Connection(database: database, references: 1)
            state.connections[url] = newConnection
            return newConnection.database
        }
    }

    func releaseDatabase(for url: URL) {
        state.withCriticalRegion { state in
            if var connection = state.connections[url] {
                connection.references -= 1
                if connection.references == 0 {
                    state.connections[url] = nil
                } else {
                    state.connections[url] = connection
                }
            }
        }
    }

    // MARK: Private

    private let state = ManagedCriticalState(State())

    private func newDatabase(url: URL, readonly: Bool) throws -> DatabaseWriter {
        do {
            return try attempt(times: 3) {
                var configuration = Configuration()
                configuration.readonly = readonly
                // TODO: Remove and use singletons instead.
                configuration.busyMode = .timeout(5)
                return try DatabasePool(path: url.path, configuration: configuration)
            }
        } catch {
            logger.error("Cannot open sqlite file \(url). Error: \(error)")
            throw PersistenceError(error, databaseURL: url)
        }
    }
}

public final class DatabaseConnection: Sendable {
    private struct State {
        var database: DatabaseWriter?
    }

    // MARK: Lifecycle

    public init(url: URL, readonly: Bool = true) {
        databaseURL = url
        self.readonly = readonly
    }

    deinit {
        state.withCriticalRegion { state in
            if state.database != nil {
                Self.connectionPool.releaseDatabase(for: databaseURL)
            }
        }
    }

    // MARK: Public

    public func read<T>(_ block: @Sendable @escaping (Database) throws -> T) async throws -> T {
        let database = try getDatabase()
        do {
            return try await database.read(block)
        } catch {
            logger.error("General error while executing query. Error: \(error).")
            throw PersistenceError(error, databaseURL: databaseURL)
        }
    }

    public func write<T>(_ block: @Sendable @escaping (Database) throws -> T) async throws -> T {
        let database = try getDatabase()
        do {
            return try await database.write(block)
        } catch {
            logger.error("General error while executing query. Error: \(error).")
            throw PersistenceError(error, databaseURL: databaseURL)
        }
    }

    // MARK: Internal

    let databaseURL: URL
    let readonly: Bool

    func getDatabase() throws -> DatabaseWriter {
        try state.withCriticalRegion { state in
            if let database = state.database {
                return database
            }

            let database = try Self.connectionPool.database(for: databaseURL, readonly: readonly)
            state.database = database
            return database
        }
    }

    // MARK: Private

    private static let connectionPool = DatabaseConnectionPool()

    private let state = ManagedCriticalState(State())
}

private extension PersistenceError {
    init(_ error: Error, databaseURL: URL) {
        let dbFileIssueCodes: [ResultCode] = [
            .SQLITE_PERM,
            .SQLITE_NOTADB,
            .SQLITE_CORRUPT,
            .SQLITE_CANTOPEN,
        ]

        if let error = error as? PersistenceError {
            self = error
        }
        if let error = error as? DatabaseError {
            if dbFileIssueCodes.contains(error.extendedResultCode) {
                // remove the db file as sometimes, the download is completed with error.
                try? FileManager.default.removeItem(at: databaseURL)
                logger.error("Bad file error while executing query. Error: \(error).")
                self = PersistenceError.badFile(error)
            }
        }
        self = PersistenceError.query(error)
    }
}

extension DatabaseMigrator {
    public func migrate(_ connection: DatabaseConnection) throws {
        let database = try connection.getDatabase()
        do {
            try migrate(database)
        } catch {
            throw PersistenceError(error, databaseURL: connection.databaseURL)
        }
    }
}
