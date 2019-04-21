//
//  TranslationAyahTextPersistenceBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/21/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

protocol TranslationAyahTextPersistenceBuildable {
    func build(with filePath: String) -> TranslationAyahTextPersistence
}

final class TranslationAyahTextPersistenceBuilder: TranslationAyahTextPersistenceBuildable {
    func build(with filePath: String) -> TranslationAyahTextPersistence {
        return SQLiteTranslationAyahTextPersistence(filePath: filePath)
    }
}
