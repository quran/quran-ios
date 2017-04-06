//
//  DatabaseVersionPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

protocol DatabaseVersionPersistence {
    func getTextVersion() throws -> Int
}
