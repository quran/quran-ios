//
//  TranslationTestData.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

import Foundation
import QuranText

public struct TranslationTestData {
    public static let khanTranslation = Translation(
        id: 1,
        displayName: "",
        translator: "",
        translatorForeign: "Khan & Hilai",
        fileURL: URL(validURL: "a"),
        fileName: "quran.en.khanhilali.db",
        languageCode: "",
        version: 5,
        installedVersion: 5
    )

    public static let sahihTranslation = Translation(
        id: 2,
        displayName: "",
        translator: "",
        translatorForeign: "Sahih International",
        fileURL: URL(validURL: "quran.ensi.zip"),
        fileName: "quran.ensi.db",
        languageCode: "",
        version: 1,
        installedVersion: 1
    )
}
