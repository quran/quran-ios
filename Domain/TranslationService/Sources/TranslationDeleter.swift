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
import QuranText
import SystemDependencies
import TranslationPersistence

public struct TranslationDeleter {
    // MARK: Lifecycle

    public init(databasesURL: URL, fileSystem: FileSystem = DefaultFileSystem()) {
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
        self.fileSystem = fileSystem
    }

    // MARK: Public

    public func deleteTranslation(_ translation: Translation) async throws -> Translation {
        // update the selected translations
        selectedTranslationsPreferences.remove(translation.id)

        // delete from disk
        for url in translation.localFiles {
            try? fileSystem.removeItem(at: url)
        }

        var translation = translation
        translation.installedVersion = nil
        try await persistence.update(translation)
        return translation
    }

    // MARK: Internal

    let persistence: ActiveTranslationsPersistence
    let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    let fileSystem: FileSystem
}
