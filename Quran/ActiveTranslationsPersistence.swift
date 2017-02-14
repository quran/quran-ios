//
//  ActiveTranslationsPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol ActiveTranslationsPersistence {
    func retrieveAll() throws -> [TranslationInfo]
    func insert(_ translation: TranslationInfo) throws
    func remove(_ translation: TranslationInfo) throws
}
