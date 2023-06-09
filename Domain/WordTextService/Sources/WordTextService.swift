//
//  WordTextService.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import Crashing
import Foundation
import QuranKit
import WordTextPersistence

public struct WordTextService {
    private let preferences = WordTextPreferences.shared
    private let persistence: WordTextPersistence

    public init(fileURL: URL) {
        persistence = GRDBWordTextPersistence(fileURL: fileURL)
    }

    public func textForWord(_ word: Word) async throws -> String? {
        let textType = preferences.wordTextType
        var text: String?
        switch textType {
        case .translation:
            text = try await persistence.translationForWord(word)
        case .transliteration:
            text = try await persistence.transliterationForWord(word)
        }
        return text
    }
}
