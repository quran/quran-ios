//
//  LazyConnectionWrapper.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import SQLite

class LazyConnectionWrapper {

    let sqliteFilePath: String
    let readonly: Bool

    init(sqliteFilePath: String, readonly: Bool = false) {
        self.sqliteFilePath = sqliteFilePath
        self.readonly = readonly
    }

    var instance: Connection?

    var connection: Connection {
        if let connection = instance {
            return connection
        }
        do {
            let connection = try Connection(sqliteFilePath, readonly: readonly)
            instance = connection
            return connection
        } catch {
            fatalError("Cannot open connection to sqlite file '\(sqliteFilePath)'. '\(error)'")
        }
    }
}
