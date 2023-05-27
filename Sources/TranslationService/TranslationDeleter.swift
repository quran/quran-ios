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
import SystemDependencies

public struct TranslationDeleter {
    let persistence: ActiveTranslationsPersistence
    let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    let fileSystem: FileSystem

    public init(databasesURL: URL, fileSystem: FileSystem = DefaultFileSystem()) {
        persistence = GRDBActiveTranslationsPersistence(directory: databasesURL)
        self.fileSystem = fileSystem
    }

    public func deleteTranslation(_ translation: Translation) -> Promise<Translation> {
        // update the selected translations
        selectedTranslationsPreferences.remove(translation.id)

        return DispatchQueue.global()
            .async(.promise) {
                // delete from disk
                translation.possibleFileNames.forEach { fileName in
                    let url = Translation.localTranslationsURL.appendingPathComponent(fileName)
                    try? fileSystem.removeItem(at: url)
                }
            }
            .then { () -> Promise<Translation> in
                DispatchQueue.global().asyncPromise {
                    var translation = translation
                    translation.installedVersion = nil
                    try await persistence.update(translation)
                    return translation
                }
            }
    }
}
