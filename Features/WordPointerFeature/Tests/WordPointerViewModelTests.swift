//
//  WordPointerViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import QuranKit
import TestResources
import UIKit
import WordTextService
import XCTest
@testable import WordPointerFeature

@MainActor
final class WordPointerViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        WordTextPreferences.shared.wordTextType = .translation
        viewModel = WordPointerViewModel(service: WordTextService(fileURL: TestResources.resourceURL("words.db")))
        viewModel.listener = listener
    }

    func testPanningOverWordShowsItsTranslation() async {
        let result = await viewModel.viewPanned(to: .zero)

        XCTAssertEqual(result, .showPopover(text: "(of) your Lord"))
    }

    func testCancelledLookupDoesNotShowPopover() async {
        let lookup = Task { await viewModel.viewPanned(to: .zero) }
        lookup.cancel()

        let result = await lookup.value

        XCTAssertEqual(result, .none)
    }

    func testCancelledLookupDoesNotHideNextLookupForSameWord() async {
        let staleLookup = Task { await viewModel.viewPanned(to: .zero) }
        staleLookup.cancel()
        _ = await staleLookup.value

        let result = await viewModel.viewPanned(to: .zero)

        XCTAssertEqual(result, .showPopover(text: "(of) your Lord"))
    }

    // MARK: Private

    private var viewModel: WordPointerViewModel!
    private let listener = WordPointerListenerFake(
        word: Word(verse: AyahNumber(quran: Quran.hafsMadani1405, sura: 110, ayah: 3)!, wordNumber: 3)
    )
}

@MainActor
private final class WordPointerListenerFake: WordPointerListener {
    // MARK: Lifecycle

    init(word: Word?) {
        self.word = word
    }

    // MARK: Internal

    func onWordPointerPanBegan() { }

    func word(at point: CGPoint) -> Word? {
        word
    }

    func highlightWord(_ position: Word?) { }

    // MARK: Private

    private let word: Word?
}
