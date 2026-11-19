//
//  ContentTranslationFootnoteTests.swift
//

import QuranKit
import QuranText
import QuranTextKit
import XCTest
@testable import QuranTranslationFeature

@MainActor
final class ContentTranslationFootnoteTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        QuranContentStatePreferences.shared.showFootnotesInTranslation = false
    }

    override func tearDown() {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = false
        super.tearDown()
    }

    func testFootnoteVisibilityFollowsPreference() throws {
        let sut = makeContentTranslationViewModel()
        commit([try footnotedString("Guide us[1] to the Straight Way.", footnotes: ["[[Lit., lead us.]]"])], to: sut)
        XCTAssertEqual(footnoteChunks(in: sut), [])

        QuranContentStatePreferences.shared.showFootnotesInTranslation = true

        XCTAssertEqual(footnoteChunks(in: sut).map(\.footnoteIndex), [0])
    }

    func testFootnotesFollowTheirTranslationTextBeforeTheTranslatorName() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        let footnoted = try footnotedString("Guide us[1] to the Straight Way.[2]", footnotes: ["[[Lit., lead us.]]", "[[i.e., Islam.]]"])
        let plain = try footnotedString("Guide us to the Straight Path.", footnotes: [])
        commit([footnoted, plain], to: sut)

        let ids = sut.items(quranFont: .uthmanicHafs).map(\.id)
        let firstChunk = try XCTUnwrap(ids.firstIndex(of: .translationTextChunk(verse, translationId: 1, chunkIndex: 0)))

        XCTAssertEqual(Array(ids[firstChunk...].prefix(6)), [
            .translationTextChunk(verse, translationId: 1, chunkIndex: 0),
            .translationFootnoteChunk(verse, translationId: 1, footnoteIndex: 0, chunkIndex: 0),
            .translationFootnoteChunk(verse, translationId: 1, footnoteIndex: 1, chunkIndex: 0),
            .translator(verse, translationId: 1),
            .translationTextChunk(verse, translationId: 2, chunkIndex: 0),
            .translator(verse, translationId: 2),
        ])
    }

    func testTruncatedTranslationShowsNoFootnotesUntilExpanded() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        let text = "Guide us[1] " + String(repeating: "to the Straight Way ", count: 50) + "and beyond.[2]"
        commit([try footnotedString(text, footnotes: ["[[Lit., lead us.]]", "[[i.e., the Hereafter.]]"])], to: sut)
        XCTAssertEqual(footnoteChunks(in: sut), [])

        sut.openURL(.readMore(translationId: 1, sura: verse.sura.suraNumber, ayah: verse.ayah))

        XCTAssertEqual(footnoteChunks(in: sut).map(\.footnoteIndex), [0, 1])
    }

    func testLongFootnoteShowsItsMarkerOnTheFirstChunkOnly() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        let footnote = String(repeating: "The unseen is what is hidden from people. ", count: 30)
        commit([try footnotedString("Who believe in the unseen.[1]", footnotes: ["[[\(footnote)]]"])], to: sut)

        let chunks = footnoteChunks(in: sut)

        XCTAssertEqual(chunks.map(\.chunkIndex), [0, 1])
        XCTAssertEqual(chunks.map(\.marker), ["[1]", nil])
    }

    func testFootnoteTextDropsTheBracketsAndWhitespaceAroundIt() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        commit([try footnotedString("Who believe in the unseen[1]", footnotes: ["[[ [ (V.2:3): Al-Ghaib: the unseen.]\n]]"])], to: sut)
        sut.openURL(.footnote(translationId: 1, sura: verse.sura.suraNumber, ayah: verse.ayah, footnoteIndex: 0))

        let chunk = try XCTUnwrap(footnoteChunks(in: sut).first)

        XCTAssertEqual(String(chunk.text[chunk.chunks[chunk.chunkIndex]]), "(V.2:3): Al-Ghaib: the unseen.")
        XCTAssertEqual(sut.footnote?.text, "(V.2:3): Al-Ghaib: the unseen.")
    }

    func testFootnoteVerseReferencesAreLinksOnlyWhenTheReaderCanFollowThem() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        commit([try footnotedString("Guide us[1] to the Straight Way.", footnotes: ["[[See footnote for {2:255}.]]"])], to: sut)
        XCTAssertEqual(linkedReferences(in: footnoteChunks(in: sut)), [])

        sut.onVerseReferenceTapped = { _, _ in }

        XCTAssertEqual(linkedReferences(in: footnoteChunks(in: sut)), ["{2:255}"])
    }

    func testFootnoteLinksOnlyVersesOtherThanItsOwn() throws {
        QuranContentStatePreferences.shared.showFootnotesInTranslation = true
        let sut = makeContentTranslationViewModel()
        sut.onVerseReferenceTapped = { _, _ in }
        commit([try footnotedString("Guide us[1] to the Straight Way.", footnotes: ["[[(V.{1:1}) See {2:255}, {1:8} and {115:1}.]]"])], to: sut)

        XCTAssertEqual(linkedReferences(in: footnoteChunks(in: sut)), ["{2:255}"])
    }

    func testFollowingAVerseReferenceClosesTheFootnoteAndReportsBothVerses() throws {
        let sut = makeContentTranslationViewModel()
        var followed: [String] = []
        sut.onVerseReferenceTapped = { verse, reference in
            followed.append("\(verse.sura.suraNumber):\(verse.ayah) → \(reference.sura.suraNumber):\(reference.ayah)")
        }
        commit([try footnotedString("Guide us[1] to the Straight Way.", footnotes: ["[[See {2:255}.]]"])], to: sut)
        sut.openURL(.footnote(translationId: 1, sura: verse.sura.suraNumber, ayah: verse.ayah, footnoteIndex: 0))
        XCTAssertEqual(sut.footnote?.verseReferences.count, 1)

        sut.openURL(.verseReference(sura: verse.sura.suraNumber, ayah: verse.ayah, referencedSura: 2, referencedAyah: 255))

        XCTAssertNil(sut.footnote)
        XCTAssertEqual(followed, ["1:1 → 2:255"])
    }

    // MARK: Private

    private let verse = Quran.hafsMadani1405.firstVerse

    private func commit(_ strings: [TranslationString], to viewModel: ContentTranslationViewModel) {
        viewModel.commitLoadedContent(
            verses: [verse],
            translations: strings.indices.map { makeTranslation(id: $0 + 1) },
            verseTexts: [verse: makeVerseText(translations: strings)]
        )
    }

    private func footnoteChunks(in viewModel: ContentTranslationViewModel) -> [TranslationFootnoteChunk] {
        viewModel.items(quranFont: .uthmanicHafs).compactMap { item in
            guard case .translationFootnoteChunk(let chunk, _) = item else { return nil }
            return chunk
        }
    }

    private func linkedReferences(in chunks: [TranslationFootnoteChunk]) -> [String] {
        chunks.flatMap { chunk in chunk.verseReferences.map { String(chunk.text[$0.range]) } }
    }

    /// Marks each "[n]" in text as the marker of footnotes[n - 1].
    private func footnotedString(_ text: String, footnotes: [Substring]) throws -> TranslationString {
        let markerRanges = try footnotes.indices.map { index in
            try XCTUnwrap(text.range(of: "[\(index + 1)]"))
        }
        return TranslationString(text: text, quranRanges: [], footnoteRanges: markerRanges, footnotes: footnotes)
    }
}
