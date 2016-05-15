//
//  SQLitePersistenceStorage.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

protocol SQLitePersistenceStorage {
    func executeQuery(table: String,
                      columns: [String],
                      `where`: String?,
                      groupBy: String?,
                      orderBy: String?,
                      onCompletion: Result<[SqliteRow]> -> Void)
}
