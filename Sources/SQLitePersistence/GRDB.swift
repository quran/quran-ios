//
//  GRDB.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation
import GRDB
import VLogging

extension DatabasePool {
    public static func newInstance(filePath: String, readOnly: Bool = false) -> DatabasePool {
        do {
            // Create the database folder if needed
            try? FileManager.default.createDirectory(atPath: filePath.stringByDeletingLastPathComponent,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)

            var configuration = Configuration()
            configuration.readonly = readOnly

            // Open or create the database
            let dbPool = try DatabasePool(path: filePath, configuration: configuration)
            return dbPool
        } catch {
            logger.error("Cannot open sqlite file \(filePath). Error: \(error)")
            fatalError("Cannot open sqlite file \(filePath.lastPathComponent)")
        }
    }
}
