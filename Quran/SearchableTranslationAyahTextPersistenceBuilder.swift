//
//  SearchableTranslationAyahTextPersistenceBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

protocol SearchableTranslationAyahTextPersistenceBuildable {
    func build(with filePath: String) -> SearchableAyahTextPersistence
}

final class SearchableTranslationAyahTextPersistenceBuilder: SearchableTranslationAyahTextPersistenceBuildable {
    func build(with filePath: String) -> SearchableAyahTextPersistence {
        return SQLiteSearchableAyahTextPersistence(filePath: filePath)
    }
}
