//
//  TranslationDeletionInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import PromiseKit

class TranslationDeletionInteractor: Interactor {

    private let persistence: ActiveTranslationsPersistence
    private let simplePersistence: SimplePersistence

    init(persistence: ActiveTranslationsPersistence, simplePersistence: SimplePersistence) {
        self.persistence = persistence
        self.simplePersistence = simplePersistence
    }

    func execute(_ item: TranslationFull) -> Promise<TranslationFull> {

        // update the selected translations
        let translations = simplePersistence.valueForKey(.selectedTranslations)
        var updatedTranslations: [Int] = []
        for id in translations where item.translation.id != id {
            updatedTranslations.append(id)
        }
        if translations != updatedTranslations {
            simplePersistence.setValue(updatedTranslations, forKey: .selectedTranslations)
        }

        return DispatchQueue.default
            .promise2 {
                // delete from disk
                item.translation.possibleFileNames.forEach { fileName in
                    let url = Files.translationsURL.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            .then { () -> TranslationFull in
                var translation = item.translation
                translation.installedVersion = nil
                try self.persistence.update(translation)
                return TranslationFull(translation: translation, response: item.response)
        }
    }
}
