//
//  WordTextServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2022-01-17.
//

import QuranKit
@testable import QuranTextKit
import XCTest

class WordTextServiceTests: XCTestCase {
    private var service: WordTextService!
    private let word = Word(verse: AyahNumber(quran: Quran.madani, sura: 110, ayah: 3)!, wordNumber: 3)
    private let preferences = DefaultsQuranContentStatePreferences()

    override func setUpWithError() throws {
        service = WordTextService(fileURL: TestData.resourceURL("words.db"))
    }

    func testWordEnglishTranslation() throws {
        preferences.wordTextType = .translation
        let text = try service.textForWord(word)
        XCTAssertEqual(text, "(of) your Lord")
    }

    func testWordEnglishTransliteration() throws {
        preferences.wordTextType = .transliteration
        let text = try service.textForWord(word)
        XCTAssertEqual(text, "rabbika")
    }
}
