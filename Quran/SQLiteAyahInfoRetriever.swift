//
//  SQLiteAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteAyahInfoRetriever: AyahInfoRetriever {

    let persistence: AyahInfoPersistenceStorage

    func retrieveAyahsAtPage(page: Int, onCompletion: Result<[AyahNumber : [AyahInfo]], PersistenceError> -> Void) {
        Queue.background.async {
            let result = try? self.persistence.getAyahInfoForPage(page)
            Queue.main.async {
                if let ayahinfoList = result { onCompletion(Result.Success(ayahinfoList)) }
            }
        }
    }
}
