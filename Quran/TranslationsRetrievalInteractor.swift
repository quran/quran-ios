//
//  TranslationsRetrievalInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation
import PromiseKit

class TranslationsRetrievalInteractor: Interactor {

    private let networkManager: AnyNetworkManager<[Translation]>
    private let persistence: ActiveTranslationsPersistence
    private let localInteractor: AnyInteractor<Void, [TranslationFull]>

    init(networkManager: AnyNetworkManager<[Translation]>,
         persistence: ActiveTranslationsPersistence,
         localInteractor: AnyInteractor<Void, [TranslationFull]>) {
        self.networkManager = networkManager
        self.persistence = persistence
        self.localInteractor = localInteractor
    }

    func execute(_ input: Void) -> Promise<[TranslationFull]> {

        let local = DispatchQueue.global().promise(execute: persistence.retrieveAll)
        let remote = networkManager.execute(.translations)

        return when(fulfilled: local, remote)                       // get local and remote
            .then(on: .global(), execute: combine)                  // combine local and remote
            .then(on: .global(), execute: saveCombined)         // save combined list
            .then(on: .global(), execute: localInteractor.execute)  // get local data
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
        combinedList.append(contentsOf: localMap.map { $1})
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
