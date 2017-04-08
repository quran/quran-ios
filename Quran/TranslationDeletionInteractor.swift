//
//  TranslationDeletionInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/12/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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

        return DispatchQueue.global()
            .promise {
                // delete from disk
                item.translation.possibleFileNames.forEach { fileName in
                    let url = Files.translationsURL.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            .then(on: .global()) { () -> TranslationFull in
                var translation = item.translation
                translation.installedVersion = nil
                try self.persistence.update(translation)
                return TranslationFull(translation: translation, downloadResponse: item.downloadResponse)
        }
    }
}
