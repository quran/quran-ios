//
//  LocalTranslationsRetrievalInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/7/17.
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
