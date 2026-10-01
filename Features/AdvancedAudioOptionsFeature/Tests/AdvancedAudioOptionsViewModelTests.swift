//
//  AdvancedAudioOptionsViewModelTests.swift
//

import Foundation
import QueuePlayer
import QuranAudio
import QuranAudioKit
import QuranKit
import ReciterListFeature
import XCTest
@testable import AdvancedAudioOptionsFeature

@MainActor
final class AdvancedAudioOptionsViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        originalAudioEnd = AudioPreferences.shared.audioEnd
        AudioPreferences.shared.audioEnd = .juz
    }

    override func tearDown() async throws {
        if let originalAudioEnd {
            AudioPreferences.shared.audioEnd = originalAudioEnd
        }
        try await super.tearDown()
    }

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

    // MARK: - EndAt prefers the saved Play up to preference

    func test_init_prefersSavedAudioEnd_whenEndMatchesSeveralBoundaries() {
        // Al-Fatihah fills page 1, so its last verse ends both the surah and the page.
        let alFatihah = quran.suras[0]
        XCTAssertEqual(PageBasedLastAyahFinder().findLastAyah(startAyah: alFatihah.firstVerse), alFatihah.lastVerse)
        AudioPreferences.shared.audioEnd = .page

        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        XCTAssertEqual(sut.endAt, .page)
    }

    func test_init_prefersSavedJuz_overSurah_whenJuzAndSurahEndTogether() {
        // Juz' 29 ends with Al-Mursalat.
        let alMursalat = quran.suras[76]
        XCTAssertEqual(JuzBasedLastAyahFinder().findLastAyah(startAyah: alMursalat.firstVerse), alMursalat.lastVerse)
        AudioPreferences.shared.audioEnd = .juz

        let sut = makeSUT(start: alMursalat.firstVerse, end: alMursalat.lastVerse)

        XCTAssertEqual(sut.endAt, .juz)
    }

    func test_init_prefersSavedAudioEnd_whenEndIsThePageFlooredBoundary() {
        // Al-Qadr ends mid-page, so the banner's range runs to the end of its page.
        let alQadr = quran.suras[96]
        let suraEnd = SuraBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse)
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse)
        XCTAssertLessThan(suraEnd, pageEnd)
        AudioPreferences.shared.audioEnd = .sura

        let sut = makeSUT(start: alQadr.firstVerse, end: pageEnd)

        XCTAssertEqual(sut.endAt, .surah)
    }

    func test_init_prefersSavedQuarter_whenEndIsTheExactQuarterEnd() {
        // Quarter 9 ends at Al-Baqarah 157, mid-page.
        AudioPreferences.shared.audioEnd = .quarter

        let sut = makeSUT(start: ayah(2, 154), end: ayah(2, 157))

        XCTAssertEqual(sut.endAt, .quarter)
    }

    func test_init_prefersSavedHizb_whenEndIsTheExactHizbEnd() {
        // Hizb 1 ends at Al-Baqarah 74, mid-page.
        AudioPreferences.shared.audioEnd = .hizb

        let sut = makeSUT(start: ayah(2, 70), end: ayah(2, 74))

        XCTAssertEqual(sut.endAt, .hizb)
    }

    func test_init_prefersSavedQuarter_overJuz_whenTheyEndTogether() {
        // Juz' 1 ends at Al-Baqarah 141, which also ends its last hizb and quarter.
        AudioPreferences.shared.audioEnd = .quarter

        let sut = makeSUT(start: ayah(2, 124), end: ayah(2, 141))

        XCTAssertEqual(sut.endAt, .quarter)
    }

    func test_init_doesNotMatchSavedQuarter_onThePageFlooredEnd() {
        // Quarter and Hizb end exactly, so the end of the start page isn't a quarter end.
        AudioPreferences.shared.audioEnd = .quarter
        let start = ayah(2, 154)
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: start)

        let sut = makeSUT(start: start, end: pageEnd)

        XCTAssertEqual(sut.endAt, .page)
    }

    func test_init_fallsBackToJuz_overHizbAndQuarter_whenTheyEndTogether() {
        AudioPreferences.shared.audioEnd = .sura

        let sut = makeSUT(start: ayah(2, 124), end: ayah(2, 141))

        XCTAssertEqual(sut.endAt, .juz)
    }

    func test_init_fallsBackToHizb_overQuarter_whenTheyEndTogether() {
        // Al-Baqarah 60 starts hizb 1's last quarter; both end at 74.
        AudioPreferences.shared.audioEnd = .quran

        let sut = makeSUT(start: ayah(2, 60), end: ayah(2, 74))

        XCTAssertEqual(sut.endAt, .hizb)
    }

    func test_init_fallsBackToQuarter_whenOnlyTheQuarterEnds() {
        AudioPreferences.shared.audioEnd = .quran

        let sut = makeSUT(start: ayah(2, 154), end: ayah(2, 157))

        XCTAssertEqual(sut.endAt, .quarter)
    }

    func test_init_fallsBackToDeduction_whenSavedAudioEndDoesNotMatch() {
        let alFatihah = quran.suras[0]
        AudioPreferences.shared.audioEnd = .quran

        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        XCTAssertEqual(sut.endAt, .surah)
    }

    // MARK: - Saving End at as the Play up to preference

    func test_play_savesSelectedEndAt_asAudioEnd() {
        let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse)

        sut.setEndAt(.surah)
        sut.play()

        XCTAssertEqual(AudioPreferences.shared.audioEnd, .sura)
    }

    func test_play_savesEveryBoundaryChoice_asMatchingAudioEnd() {
        let expected: [(EndAtChoice, AudioEnd)] = [
            (.page, .page), (.quarter, .quarter), (.hizb, .hizb), (.surah, .sura), (.juz, .juz), (.quran, .quran),
        ]
        for (choice, audioEnd) in expected {
            AudioPreferences.shared.audioEnd = audioEnd == .juz ? .page : .juz
            let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse)

            sut.setEndAt(choice)
            sut.play()

            XCTAssertEqual(AudioPreferences.shared.audioEnd, audioEnd, "\(choice)")
        }
    }

    func test_play_withoutChoosingEndAt_keepsAudioEnd_evenWhenDeducedChoiceDiffers() {
        let alFatihah = quran.suras[0]
        AudioPreferences.shared.audioEnd = .juz
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)
        XCTAssertEqual(sut.endAt, .surah)

        sut.play()

        XCTAssertEqual(AudioPreferences.shared.audioEnd, .juz)
    }

    func test_play_afterChoosingPage_savesPage() {
        let alFatihah = quran.suras[0]
        AudioPreferences.shared.audioEnd = .juz
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        sut.setEndAt(.page)
        sut.play()

        XCTAssertEqual(AudioPreferences.shared.audioEnd, .page)
    }

    func test_play_afterChoosingSurahThenEditingTo_keepsAudioEnd() {
        let alBaqarah = quran.suras[1]
        AudioPreferences.shared.audioEnd = .juz
        let sut = makeSUT(start: alBaqarah.firstVerse, end: alBaqarah.firstVerse)

        sut.setEndAt(.surah)
        sut.updateToVerseTo(alBaqarah.firstVerse.next!)
        sut.play()

        XCTAssertEqual(sut.endAt, .custom)
        XCTAssertEqual(AudioPreferences.shared.audioEnd, .juz)
    }

    func test_play_withCustomEndAt_keepsAudioEnd() {
        AudioPreferences.shared.audioEnd = .page
        let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse.next!)
        XCTAssertEqual(sut.endAt, .custom)

        sut.play()

        XCTAssertEqual(AudioPreferences.shared.audioEnd, .page)
    }

    func test_dismiss_keepsAudioEnd_afterChangingEndAt() {
        AudioPreferences.shared.audioEnd = .page
        let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse)

        sut.setEndAt(.quran)
        sut.dismiss()

        XCTAssertEqual(AudioPreferences.shared.audioEnd, .page)
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

    func test_setEndAt_hizb_updatesToVerseToTheExactHizbEnd() {
        let sut = makeSUT(start: ayah(2, 70), end: ayah(2, 70))

        sut.setEndAt(.hizb)

        XCTAssertEqual(sut.toVerse, ayah(2, 74))
    }

    func test_updateFromVerseTo_reAppliesQuarter_withoutThePageFloor() {
        let sut = makeSUT(start: ayah(2, 142), end: ayah(2, 142))
        sut.setEndAt(.quarter)
        XCTAssertEqual(sut.toVerse, ayah(2, 157))

        sut.updateFromVerseTo(ayah(2, 158))

        XCTAssertEqual(sut.toVerse, ayah(2, 176))
    }

    func test_setEndAt_custom_doesNotChangeToVerse() {
        let start = quran.suras[0].firstVerse
        let originalEnd = start.next!
        let sut = makeSUT(start: start, end: originalEnd)

        sut.setEndAt(.custom)

        XCTAssertEqual(sut.endAt, .custom)
        XCTAssertEqual(sut.toVerse, originalEnd)
    }

    // MARK: - Play up to menu

    func test_playUpToSelection_isTheEndAtChoice_whenNotCustom() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        XCTAssertEqual(sut.playUpToSelection, .surah)
    }

    func test_playUpToSelection_isNil_afterEditingTo() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)

        sut.updateToVerseTo(alFatihah.firstVerse.next!)

        XCTAssertEqual(sut.endAt, .custom)
        XCTAssertNil(sut.playUpToSelection)
    }

    func test_selectPlayUpTo_newChoice_updatesToAndIsSavedOnPlay() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.firstVerse)

        sut.selectPlayUpTo(.surah)
        sut.play()

        XCTAssertEqual(sut.toVerse, alFatihah.lastVerse)
        XCTAssertEqual(AudioPreferences.shared.audioEnd, .sura)
    }

    func test_selectPlayUpTo_quarter_endsToExactlyAndIsSavedOnPlay() {
        // Quarter 9 ends at Al-Baqarah 157, mid-page 24 (2:154–163).
        let start = ayah(2, 154)
        let sut = makeSUT(start: start, end: start)

        sut.selectPlayUpTo(.quarter)
        sut.play()

        XCTAssertEqual(sut.toVerse, ayah(2, 157))
        XCTAssertEqual(AudioPreferences.shared.audioEnd, .quarter)
    }

    func test_selectPlayUpTo_currentChoice_keepsToAndAudioEnd() {
        // Al-Qadr ends mid-page, so choosing Surah again would move To to the end of its page.
        let alQadr = quran.suras[96]
        let suraEnd = SuraBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse)
        XCTAssertLessThan(suraEnd, PageBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse))
        let sut = makeSUT(start: alQadr.firstVerse, end: suraEnd)
        XCTAssertEqual(sut.endAt, .surah)

        sut.selectPlayUpTo(.surah)
        sut.play()

        XCTAssertEqual(sut.toVerse, suraEnd)
        XCTAssertEqual(AudioPreferences.shared.audioEnd, .juz, "Re-selecting the deduced choice isn't choosing it.")
    }

    // MARK: - Manual verse updates

    func test_updateToVerseTo_switchesEndAtToCustom() {
        let alFatihah = quran.suras[0]
        let sut = makeSUT(start: alFatihah.firstVerse, end: alFatihah.lastVerse)
        XCTAssertEqual(sut.endAt, .surah)

        sut.updateToVerseTo(alFatihah.firstVerse.next!)

        XCTAssertEqual(sut.endAt, .custom)
    }

    func test_updateToVerseTo_clampsEndToStart_whenSelectionIsEarlier() {
        let alFatihah = quran.suras[0]
        let start = alFatihah.firstVerse.next!
        let sut = makeSUT(start: start, end: alFatihah.lastVerse)

        sut.updateToVerseTo(alFatihah.firstVerse)

        XCTAssertEqual(sut.fromVerse, start)
        XCTAssertEqual(sut.toVerse, start)
        XCTAssertEqual(sut.endAt, .custom)
    }

    func test_init_clampsEndToStart_whenOptionsEndIsEarlier() {
        let alFatihah = quran.suras[0]
        let start = alFatihah.firstVerse.next!

        let sut = makeSUT(start: start, end: alFatihah.firstVerse)

        XCTAssertEqual(sut.fromVerse, start)
        XCTAssertEqual(sut.toVerse, start)
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

    func test_updateFromVerseTo_floorsSurahEndToTheStartPage() {
        // Al-Qadr ends mid-page, so Surah plays on to the end of that page, as
        // the banner and the ayah menu do.
        let alQadr = quran.suras[96]
        let newStart = alQadr.firstVerse.next!.next!
        let pageEnd = PageBasedLastAyahFinder().findLastAyah(startAyah: newStart)
        XCTAssertLessThan(alQadr.lastVerse, pageEnd)
        AudioPreferences.shared.audioEnd = .sura
        let sut = makeSUT(
            start: alQadr.firstVerse,
            end: PageBasedLastAyahFinder().findLastAyah(startAyah: alQadr.firstVerse)
        )
        XCTAssertEqual(sut.endAt, .surah)

        sut.updateFromVerseTo(newStart)

        XCTAssertEqual(sut.toVerse, pageEnd)
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
        XCTAssertEqual([Runs.indefinite, .finite(3), .finite(1), .finite(5), .finite(2), .finite(4)].sorted(), [.finite(1), .finite(2), .finite(3), .finite(4), .finite(5), .indefinite])
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

    // MARK: - Playback rate

    func test_dismiss_doesNotPersistSelectedPlaybackRate() {
        let originalRate = AudioPreferences.shared.playbackRate
        defer { AudioPreferences.shared.playbackRate = originalRate }
        AudioPreferences.shared.playbackRate = 1
        let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse)

        sut.updatePlaybackRate(to: 1.25)
        sut.dismiss()

        XCTAssertEqual(AudioPreferences.shared.playbackRate, 1)
    }

    func test_play_persistsSelectedPlaybackRate() {
        let originalRate = AudioPreferences.shared.playbackRate
        defer { AudioPreferences.shared.playbackRate = originalRate }
        AudioPreferences.shared.playbackRate = 1
        let sut = makeSUT(start: quran.firstVerse, end: quran.firstVerse)

        sut.updatePlaybackRate(to: 1.25)
        sut.play()

        XCTAssertEqual(AudioPreferences.shared.playbackRate, 1.25)
    }

    // MARK: - RepetitionDelay

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

    func test_endAtChoice_menuChoices_goFromSmallestToLargest() {
        XCTAssertEqual(EndAtChoice.menuChoices, [.page, .quarter, .hizb, .juz, .surah, .quran])
    }

    func test_endAtChoice_initFromAudioEnd_roundTrips() {
        for audioEnd in [AudioEnd.page, .quarter, .hizb, .sura, .juz, .quran] {
            XCTAssertEqual(EndAtChoice(audioEnd).audioEnd, audioEnd)
        }
    }

    func test_endAtChoice_audioEndMapping() {
        XCTAssertEqual(EndAtChoice.page.audioEnd, .page)
        XCTAssertEqual(EndAtChoice.quarter.audioEnd, .quarter)
        XCTAssertEqual(EndAtChoice.hizb.audioEnd, .hizb)
        XCTAssertEqual(EndAtChoice.surah.audioEnd, .sura)
        XCTAssertEqual(EndAtChoice.juz.audioEnd, .juz)
        XCTAssertEqual(EndAtChoice.quran.audioEnd, .quran)
        XCTAssertNil(EndAtChoice.custom.audioEnd)
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405
    private var originalAudioEnd: AudioEnd?

    private func ayah(_ sura: Int, _ ayah: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }

    private func makeSUT(start: AyahNumber, end: AyahNumber, verseDelay: VerseDelay = .none) -> AdvancedAudioOptionsViewModel {
        AdvancedAudioOptionsViewModel(
            options: AdvancedAudioOptions(
                reciter: stubReciter(),
                start: start,
                end: end,
                verseRuns: .finite(1),
                listRuns: .finite(1),
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
