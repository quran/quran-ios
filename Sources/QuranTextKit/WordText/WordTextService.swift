//
//  WordTextService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import Crashing
import Foundation

public struct WordTextService {
    let preferences: QuranContentStatePreferences
    let persistence: WordTextPersistence

    public init() {
        preferences = DefaultsQuranContentStatePreferences(userDefaults: .standard)
        persistence = SQLiteWordTextPersistence()
    }

    public func textForWord(_ word: Word) throws -> String? {
        let textType = preferences.wordTextType
        var text: String?
        switch textType {
        case .translation:
            text = try persistence.translationForWord(word)
        case .transliteration:
            text = try persistence.transliterationForWord(word)
        }
        return text
    }
}
