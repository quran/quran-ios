//
//  TranslationsRetrievalInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
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

protocol TranslationsRetrieverType {
    func getTranslations() -> Promise<[TranslationFull]>
}

class TranslationsRetriever: TranslationsRetrieverType {

    private let networkManager: AnyNetworkManager<[Translation]>
    private let persistence: ActiveTranslationsPersistence
    private let localRetriever: LocalTranslationsRetrieverType

    init(networkManager: AnyNetworkManager<[Translation]>,
         persistence: ActiveTranslationsPersistence,
         localRetriever: LocalTranslationsRetrieverType) {
        self.networkManager = networkManager
        self.persistence = persistence
        self.localRetriever = localRetriever
    }

    func getTranslations() -> Promise<[TranslationFull]> {
        let local = DispatchQueue.global().async(.promise, execute: persistence.retrieveAll)
        let remote = networkManager.execute(.translations)

        return when(fulfilled: local, remote)                       // get local and remote
            .map(combine)                  // combine local and remote
            .map(saveCombined)         // save combined list
            .then(localRetriever.getLocalTranslations)  // get local data
    }

    private func combine(local: [Translation], remote: [Translation]) -> ([Translation], [Int: Translation]) {
        let localMapConstant = local.flatGroup { $0.id }
        var localMap = localMapConstant

        var combinedList: [Translation] = []
        remote.forEach { remote in
            var combined = remote
            if let local = localMap[remote.id] {
                combined.installedVersion = local.installedVersion
                localMap[remote.id] = nil
            }
            combinedList.append(combined)
        }
        combinedList.append(contentsOf: localMap.map { $1 })
        return (combinedList, localMapConstant)
    }

    private func saveCombined(translations: [Translation], localMap: [Int: Translation]) throws {
        try translations.forEach { translation in
            if localMap[translation.id] != nil {
                try self.persistence.update(translation)
            } else {
                try self.persistence.insert(translation)
            }
        }
    }
}
