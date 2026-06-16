//
//  AdvancedAudioOptionsViewModelTests.swift
//

import Foundation
import QueuePlayer
import QuranAudio
import QuranKit
import ReciterListFeature
import XCTest
@testable import AdvancedAudioOptionsFeature

@MainActor
final class AdvancedAudioOptionsViewModelTests: XCTestCase {
    // MARK: Internal

    // MARK: - EndAt deduction on init

    func test_init_deducesEndAt_asSura_whenEndIsLastVerseOfSura() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        XCTAssertEqual(sut.endAt, .surah)
    }

    func test_init_deducesEndAt_asPage_whenEndIsLastVerseOfStartPage() {
        // Al-Baqarah's start is mid-surah, so the page boundary won't coincide
        // with a surah boundary — keeps the deduction unambiguous.
        let start = quran.suras[1].firstVerse
        let end = PageBasedLastAyahFinder().findLastAyah(startAyah: start)
        let sut = makeSUT(start: start, end: end)

        XCTAssertEqual(sut.endAt, .page)
    }

    func test_init_deducesEndAt_asCustom_whenEndDoesNotMatchAnyBoundary() {
        let alBaqarah = quran.suras[1]
        let end = alBaqarah.firstVerse.next!
        let sut = makeSUT(start: alBaqarah.firstVerse, end: end)

        XCTAssertEqual(sut.endAt, .custom)
    }

    // MARK: - setEndAt

    func test_setEndAt_surah_updatesToVerseToEndOfSura() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.firstVerse)

        sut.setEndAt(.surah)

        XCTAssertEqual(sut.endAt, .surah)
        XCTAssertEqual(sut.toVerse, alFatihah.lastVerse)
    }

    func test_setEndAt_page_updatesToVerseToEndOfPage() {
        let start = quran.firstVerse
        let sut = makeSUT(start: start, end: start)

        sut.setEndAt(.page)

        XCTAssertEqual(sut.endAt, .page)
        XCTAssertEqual(sut.toVerse, PageBasedLastAyahFinder().findLastAyah(startAyah: start))
    }

    func test_setEndAt_custom_doesNotChangeToVerse() {
        let start = quran.suras[0].firstVerse
        let originalEnd = start.next!
        let sut = makeSUT(start: start, end: originalEnd)

        sut.setEndAt(.custom)

        XCTAssertEqual(sut.endAt, .custom)
        XCTAssertEqual(sut.toVerse, originalEnd)
    }

    // MARK: - Manual verse updates

    func test_updateToVerseTo_switchesEndAtToCustom() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)
        XCTAssertEqual(sut.endAt, .surah)

        sut.updateToVerseTo(alFatihah.firstVerse.next!)

        XCTAssertEqual(sut.endAt, .custom)
    }

    func test_updateFromVerseTo_reAppliesEndAt_whenNotCustom() {
        let alFatihah = quran.suras[0]
        let alBaqarah = quran.suras[1]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)
        sut.setEndAt(.surah)

        sut.updateFromVerseTo(alBaqarah.firstVerse)

        XCTAssertEqual(
            sut.toVerse,
            alBaqarah.lastVerse,
            "Switching surah while .surah is selected should re-end on the new surah"
        )
    }

    func test_updateFromVerseTo_keepsCustomEnd_whenNotPastNewStart() {
        let alFatihah = quran.suras[0]
        let customEnd = alFatihah.firstVerse.next!.next!
        let sut = makeSUT(start: alFatihah.firstVerse, end: customEnd)
        XCTAssertEqual(sut.endAt, .custom)

        let newStart = alFatihah.firstVerse.next!
        sut.updateFromVerseTo(newStart)

        XCTAssertEqual(sut.endAt, .custom)
        XCTAssertEqual(sut.toVerse, customEnd)
    }

    func test_updateFromVerseTo_widensCustomEnd_whenPastNewStart() {
        let alFatihah = quran.suras[0]
        let originalEnd = alFatihah.firstVerse.next!
        let sut = makeSUT(start: alFatihah.firstVerse, end: originalEnd)
        XCTAssertEqual(sut.endAt, .custom)

        let newStart = alFatihah.lastVerse
        sut.updateFromVerseTo(newStart)

        XCTAssertEqual(
            sut.toVerse,
            newStart,
            "When the new start passes the existing custom end, end should follow start."
        )
    }

    // MARK: - Runs

    func test_runsComparable_sortsByIncreasingMaxRuns() {
        XCTAssertEqual([Runs.indefinite, .three, .one, .five, .two, .four].sorted(), [.one, .two, .three, .four, .five, .indefinite])
    }

    func test_runsLocalizedDescription_finiteValuesFormatLocalizedNumbersWithMultiplicationSign() {
        XCTAssertEqual(Runs.one.localizedDescription, "1×")
        XCTAssertEqual(Runs.two.localizedDescription, "2×")
        XCTAssertEqual(Runs.three.localizedDescription, "3×")
        XCTAssertEqual(Runs.four.localizedDescription, "4×")
        XCTAssertEqual(Runs.five.localizedDescription, "5×")
    }

    func test_runsCustom_localizedDescriptionFormatsCountWithMultiplicationSign() {
        XCTAssertEqual(Runs.custom(7).localizedDescription, "7×")
        XCTAssertEqual(Runs.custom(30).localizedDescription, "30×")
    }

    // MARK: - Verse delay

    func test_init_seedsVerseDelay_fromOptions() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse, verseDelay: .half)

        XCTAssertEqual(sut.verseDelay, .half)
    }

    func test_init_defaultsVerseDelay_toNone() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        XCTAssertEqual(sut.verseDelay, .none)
    }

    func test_play_propagatesSelectedVerseDelay_toListener() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)
        let listener = ListenerSpy()
        sut.listener = listener

        sut.verseDelay = .threeQuarters
        sut.play()

        XCTAssertEqual(listener.updatedOptions?.verseDelay, .threeQuarters)
    }

    func test_verseDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(VerseDelay.sorted, [.none, .quarter, .half, .threeQuarters, .full, .double])
    }

    // MARK: - RepetitionDelay

    func test_repetitionDelaySorted_matchesExpectedOrder() {
        XCTAssertEqual(RepetitionDelay.sorted, [.none, .oneSecond, .twoSeconds, .threeSeconds, .fiveSeconds, .tenSeconds])
    }

    func test_repetitionDelayComparable_sortsByIncreasingSeconds() {
        let unorderedDelays: [RepetitionDelay] = [.fiveSeconds, .none, .tenSeconds, .twoSeconds, .oneSecond, .threeSeconds]
        let seconds = unorderedDelays.sorted().map(\.seconds)

        XCTAssertEqual(seconds, seconds.sorted())
    }

    func test_repetitionDelaySeconds_matchesExpectedValues() {
        XCTAssertEqual(RepetitionDelay.none.seconds, 0)
        XCTAssertEqual(RepetitionDelay.oneSecond.seconds, 1)
        XCTAssertEqual(RepetitionDelay.twoSeconds.seconds, 2)
        XCTAssertEqual(RepetitionDelay.threeSeconds.seconds, 3)
        XCTAssertEqual(RepetitionDelay.fiveSeconds.seconds, 5)
        XCTAssertEqual(RepetitionDelay.tenSeconds.seconds, 10)
    }

    // MARK: - EndAtChoice

    func test_endAtChoice_audioEndMapping() {
        XCTAssertEqual(EndAtChoice.page.audioEnd, .page)
        XCTAssertEqual(EndAtChoice.surah.audioEnd, .sura)
        XCTAssertEqual(EndAtChoice.juz.audioEnd, .juz)
        XCTAssertEqual(EndAtChoice.quran.audioEnd, .quran)
        XCTAssertNil(EndAtChoice.custom.audioEnd)
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    private func makeSUT(start: AyahNumber, end: AyahNumber, verseDelay: VerseDelay = .none) -> AdvancedAudioOptionsViewModel {
        AdvancedAudioOptionsViewModel(
            options: AdvancedAudioOptions(
                reciter: stubReciter(),
                start: start,
                end: end,
                verseRuns: .one,
                listRuns: .one,
                verseDelay: verseDelay
            ),
            reciterListBuilder: ReciterListBuilder()
        )
    }

    private func stubReciter() -> Reciter {
        Reciter(
            id: 1,
            nameKey: "test",
            directory: "test",
            audioURL: URL(string: "http://example.com")!,
            audioType: .gapless(databaseName: "test"),
            hasGaplessAlternative: false,
            category: .arabic
        )
    }
}

@MainActor
private final class ListenerSpy: AdvancedAudioOptionsListener {
    private(set) var updatedOptions: AdvancedAudioOptions?
    private(set) var didDismiss = false

    func updateAudioOptions(to newOptions: AdvancedAudioOptions) {
        updatedOptions = newOptions
    }

    func dismissAudioOptions() {
        didDismiss = true
    }
}
