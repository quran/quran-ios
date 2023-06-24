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

import Foundation
import NetworkSupport
import QuranText
import TranslationPersistence

public struct TranslationsRepository {
    // MARK: Lifecycle

    public init(databasesURL: URL, baseURL: URL) {
        self.init(databasesURL: databasesURL, networkManager: NetworkManager(baseURL: baseURL))
    }

    init(databasesURL: URL, networkManager: NetworkManager) {
        self.networkManager = TranslationNetworkManager(networkManager: networkManager, parser: JSONTranslationsParser())
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
    }

    // MARK: Public

    public func downloadAndSyncTranslations() async throws {
        async let local = persistence.retrieveAll()
        async let remote = networkManager.getTranslations()

        let (translations, map) = try await combine(local: local, remote: remote)
        try await saveCombined(translations: translations, localMap: map)
    }

    // MARK: Internal

    let networkManager: TranslationNetworkManager
    let persistence: ActiveTranslationsPersistence

    // MARK: Private

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

    private func saveCombined(translations: [Translation], localMap: [Int: Translation]) async throws {
        for translation in translations {
            if localMap[translation.id] != nil {
                try await persistence.update(translation)
            } else {
                try await persistence.insert(translation)
            }
        }
    }
}
