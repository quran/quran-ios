//
//  SQLiteAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteAyahInfoRetriever: AyahInfoRetriever {

    let persistence: AyahInfoStorage

    func retrieveAyahsAtPage(page: Int, onCompletion: Result<[AyahNumber : [AyahInfo]], PersistenceError> -> Void) {
        Queue.background.async {
            do {
                let result = try self.persistence.getAyahInfoForPage(page)
                Queue.main.async {
                    onCompletion(Result.Success(result))
                }
            } catch {
                Queue.main.async({
                    onCompletion(Result.Failure(error as? PersistenceError ?? PersistenceError.QueryError(error: error)))
                })
            }
        }
    }
}
