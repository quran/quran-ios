//
//  SelectedTranslationsPreferencesTests.swift
//
//
//  Created by Mohamed Afifi on 2023-05-21.
//

@testable import TranslationService
import XCTest

class SelectedTranslationsPreferencesTests: XCTestCase {
    private let preferences = SelectedTranslationsPreferences.shared

    override func tearDown() {
        super.tearDown()
        preferences.reset()
    }

    func testPreferences() {
        XCTAssertEqual(preferences.selectedTranslations, [])

        preferences.toggleSelection(45)
        preferences.toggleSelection(10)
        preferences.toggleSelection(20)
        XCTAssertEqual(preferences.selectedTranslations, [45, 10, 20])
        XCTAssertTrue(preferences.isSelected(10))

        preferences.toggleSelection(10)
        XCTAssertEqual(preferences.selectedTranslations, [45, 20])
        XCTAssertFalse(preferences.isSelected(10))
    }
}
