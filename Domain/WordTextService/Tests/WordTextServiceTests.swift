//
//  WordTextServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-17.
//

import QuranKit
import TestResources
import XCTest
@testable import WordTextService

class WordTextServiceTests: XCTestCase {
    // MARK: Internal

    override func setUpWithError() throws {
        service = WordTextService(fileURL: TestResources.resourceURL("words.db"))
    }

    func testWordEnglishTranslation() async throws {
        preferences.wordTextType = .translation
        let text = try await service.textForWord(word)
        XCTAssertEqual(text, "(of) your Lord")
    }

    func testWordEnglishTransliteration() async throws {
        preferences.wordTextType = .transliteration
        let text = try await service.textForWord(word)
        XCTAssertEqual(text, "rabbika")
    }

    // MARK: Private

    private var service: WordTextService!
    private let word = Word(verse: AyahNumber(quran: Quran.hafsMadani1405, sura: 110, ayah: 3)!, wordNumber: 3)
    private let preferences = WordTextPreferences.shared
}
