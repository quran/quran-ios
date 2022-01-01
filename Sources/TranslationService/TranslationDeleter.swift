//
//  TranslationDeleter.swift
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

import Foundation
import PromiseKit

public struct TranslationDeleter {
    let persistence: ActiveTranslationsPersistence
    let selectedTranslationsPreferences: WriteableSelectedTranslationsPreferences

    public init(databasesPath: String) {
        persistence = SQLiteActiveTranslationsPersistence(directory: databasesPath)
        selectedTranslationsPreferences = DefaultsSelectedTranslationsPreferences(userDefaults: .standard)
    }

    public func deleteTranslation(_ translation: Translation) -> Promise<Translation> {
        // update the selected translations
        let translations = selectedTranslationsPreferences.selectedTranslations
        var updatedTranslations: [Int] = []
        for id in translations where translation.id != id {
            updatedTranslations.append(id)
        }
        if translations != updatedTranslations {
            selectedTranslationsPreferences.selectedTranslations = updatedTranslations
        }

        return DispatchQueue.global()
            .async(.promise) {
                // delete from disk
                translation.possibleFileNames.forEach { fileName in
                    let url = Translation.localTranslationsURL.appendingPathComponent(fileName)
                    try? FileManager.default.removeItem(at: url)
                }
            }
            .map { () -> Translation in
                var translation = translation
                translation.installedVersion = nil
                try self.persistence.update(translation)
                return translation
            }
    }
}
