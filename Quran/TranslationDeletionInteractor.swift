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

    init(persistence: ActiveTranslationsPersistence) {
        self.persistence = persistence
    }

    func execute(_ item: TranslationFull) -> Promise<TranslationFull> {

        return DispatchQueue.global()
            .promise {
                // delete from disk
                item.translation.possibleFileNames.forEach { fileName in
                    let url = Files.translationsURL.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            .then(on: .translations) { () -> TranslationFull in
                var translation = item.translation
                translation.installedVersion = nil
                try self.persistence.update(translation)
                return TranslationFull(translation: translation, downloadResponse: item.downloadResponse)
        }
    }
}
