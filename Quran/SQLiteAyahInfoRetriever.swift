//
//  SQLiteAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteAyahInfoRetriever: AyahInfoRetriever {

    let persistence: SQLitePersistenceStorage

    func retrieveAyahsAtPage(page: Int, onCompletion: Result<[AyahNumber : [AyahInfo]], PersistenceError> -> Void) {
        unimplemented()
    }
}
