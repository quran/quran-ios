//
//  ActiveTranslationsPersistence.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

protocol ActiveTranslationsPersistence {
    func retrieveAll() throws -> [Translation]
    func insert(_ translation: Translation) throws
    func remove(_ translation: Translation) throws
    func update(_ translation: Translation) throws
}
