//
//  TranslationsRepository.swift
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

import BatchDownloader
import Foundation
import PromiseKit

public struct TranslationsRepository {
    let networkManager: TranslationNetworkManager
    let persistence: ActiveTranslationsPersistence

    public init(databasesURL: URL, baseURL: URL) {
        self.init(databasesURL: databasesURL, networkManager: NetworkManager(session: .shared, baseURL: baseURL))
    }

    init(databasesURL: URL, networkManager: NetworkManager) {
        self.networkManager = DefaultTranslationNetworkManager(networkManager: networkManager, parser: JSONTranslationsParser())
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
    }

    public func downloadAndSyncTranslations() -> Promise<Void> {
        let local = DispatchQueue.global().asyncPromise {
            try await persistence.retrieveAll()
        }
        let remote = networkManager.getTranslations()

        return when(fulfilled: local, remote) // get local and remote
            .map(combine) // combine local and remote
            .then { translations, map in
                DispatchQueue.global().asyncPromise {
                    try await saveCombined(translations: translations, localMap: map)
                }
            }
    }

    private func combine(local: [Translation], remote: [Translation]) -> ([Translation], [String: Translation]) {
        let localMapConstant = local.flatGroup { $0.fileName }
        var localMap = localMapConstant

        var combinedList: [Translation] = []
        remote.forEach { remote in
            var combined = remote
            if let local = localMap[remote.fileName] {
                combined.installedVersion = local.installedVersion
                localMap[remote.fileName] = nil
            }
            combinedList.append(combined)
        }
        combinedList.append(contentsOf: localMap.map { $1 })
        return (combinedList, localMapConstant)
    }

    private func saveCombined(translations: [Translation], localMap: [String: Translation]) async throws {
        for translation in translations {
            if localMap[translation.fileName] != nil {
                try await persistence.update(translation)
            } else {
                try await persistence.insert(translation)
            }
        }
    }
}
