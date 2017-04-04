//
//  LocalTranslationsRetrievalInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/7/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit
import Zip

class LocalTranslationsRetrievalInteractor: Interactor {

    private let persistence: ActiveTranslationsPersistence
    private let versionUpdater: AnyInteractor<[Translation], [TranslationFull]>

    init(persistence: ActiveTranslationsPersistence, versionUpdater: AnyInteractor<[Translation], [TranslationFull]>) {
        self.persistence = persistence
        self.versionUpdater = versionUpdater
    }

    func execute(_ input: Void) -> Promise<[TranslationFull]> {
        return DispatchQueue.global()
            .promise(execute: persistence.retrieveAll)
            .then(on: .global(), execute: versionUpdater.execute)
    }
}
