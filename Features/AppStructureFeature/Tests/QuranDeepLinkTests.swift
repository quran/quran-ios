//
//  QuranDeepLinkTests.swift
//  Quran
//
//  Created by Abdullah Levin on 2026-09-06.
//

import QuranAudio
import QuranKit
import XCTest
@testable import AppStructureFeature

final class QuranDeepLinkTests: XCTestCase {
    // MARK: Internal

    // MARK: - Target parsing (no audio)

    func testSuraOnlyLink() {
        XCTAssertEqual(deepLink("quran://2")?.target, .sura(sura(2)))
        XCTAssertNil(deepLink("quran://2")?.audio)
    }

    func testSuraAndAyahLink() {
        XCTAssertEqual(deepLink("quran://2/255")?.target, .ayah(ayah(sura: 2, ayah: 255)))
        XCTAssertNil(deepLink("quran://2/255")?.audio)
    }

    func testLegacySchemeIsSupported() {
        XCTAssertEqual(deepLink("quran-ios://114/6")?.target, .ayah(ayah(sura: 114, ayah: 6)))
    }

    func testSchemeIsCaseInsensitive() {
        XCTAssertEqual(deepLink("QURAN://1/1")?.target, .ayah(ayah(sura: 1, ayah: 1)))
    }

    func testTrailingSlashIsIgnored() {
        XCTAssertEqual(deepLink("quran://18/")?.target, .sura(sura(18)))
    }

    func testNonNumericSegmentsAreSkipped() {
        XCTAssertEqual(deepLink("quran://sura/2/255")?.target, .ayah(ayah(sura: 2, ayah: 255)))
    }

    func testExtraSegmentsAreIgnored() {
        XCTAssertEqual(deepLink("quran://2/255/anything")?.target, .ayah(ayah(sura: 2, ayah: 255)))
    }

    func testFirstAndLastAyahOfTheQuran() {
        XCTAssertEqual(deepLink("quran://1/1")?.target, .ayah(quran.firstVerse))
        XCTAssertEqual(deepLink("quran://114/6")?.target, .ayah(quran.lastVerse))
    }

    func testUnsupportedSchemeIsRejected() {
        XCTAssertNil(deepLink("https://quran.com/2/255"))
        XCTAssertNil(deepLink("quranx://2/255"))
    }

    func testLinkWithoutSuraIsRejected() {
        XCTAssertNil(deepLink("quran://"))
        XCTAssertNil(deepLink("quran://home"))
    }

    func testSuraOutOfRangeIsRejected() {
        XCTAssertNil(deepLink("quran://0"))
        XCTAssertNil(deepLink("quran://115"))
        XCTAssertNil(deepLink("quran://999"))
    }

    func testAyahOutOfRangeIsRejected() {
        XCTAssertNil(deepLink("quran://2/0"))
        XCTAssertNil(deepLink("quran://2/287"))
        XCTAssertNil(deepLink("quran://1/8"))
    }

    func testLastAyahOfSuraIsAccepted() {
        XCTAssertEqual(deepLink("quran://2/286")?.target, .ayah(ayah(sura: 2, ayah: 286)))
    }

    // MARK: - play flag

    func testPlayTrueEnablesAudio() {
        let audio = deepLink("quran://2/255?play=true")?.audio
        XCTAssertEqual(audio, defaultAudio())
    }

    func testPlayOneEnablesAudio() {
        let audio = deepLink("quran://2/255?play=1")?.audio
        XCTAssertEqual(audio, defaultAudio())
    }

    func testPlayIsCaseInsensitive() {
        let audio = deepLink("quran://2/255?play=TRUE")?.audio
        XCTAssertEqual(audio, defaultAudio())
    }

    func testPlayFalseValueDoesNotEnableAudio() {
        XCTAssertNil(deepLink("quran://2/255?play=false")?.audio)
        XCTAssertNil(deepLink("quran://2/255?play=0")?.audio)
    }

    func testMissingPlayLeavesAudioNil() {
        XCTAssertNil(deepLink("quran://2/255")?.audio)
    }

    func testAudioParametersAreIgnoredWithoutPlay() {
        let link = deepLink("quran://2/255?to=2:257&verse_repeat=3&range_repeat=infinite&reciter=5&speed=1.5")
        XCTAssertEqual(link?.target, .ayah(ayah(sura: 2, ayah: 255)))
        XCTAssertNil(link?.audio)
    }

    func testInvalidAudioParametersAreIgnoredWithoutPlay() {
        let link = deepLink("quran://2/255?to=garbage&verse_repeat=abc&reciter=-1&speed=fast")
        XCTAssertEqual(link?.target, .ayah(ayah(sura: 2, ayah: 255)))
        XCTAssertNil(link?.audio)
    }

    func testPlaySuraOnlyLink() {
        let link = deepLink("quran://2?play=true")
        XCTAssertEqual(link?.target, .sura(sura(2)))
        XCTAssertEqual(link?.audio, defaultAudio())
    }

    // MARK: - verse_repeat

    func testRepeatCountsDefaultToOneWhenPlayIsPresent() {
        let audio = deepLink("quran://2/255?play=true")?.audio
        XCTAssertEqual(audio?.verseRuns, .finite(1))
        XCTAssertEqual(audio?.listRuns, .finite(1))
    }

    func testVerseRepeatCountSetsFiniteRuns() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=3")?.audio
        XCTAssertEqual(audio?.verseRuns, .finite(3))
    }

    func testVerseRepeatInfiniteIsIndefinite() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=infinite")?.audio
        XCTAssertEqual(audio?.verseRuns, .indefinite)
    }

    func testVerseRepeatInfiniteIsCaseInsensitive() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=INFINITE")?.audio
        XCTAssertEqual(audio?.verseRuns, .indefinite)
    }

    func testVerseRepeatLowerBoundIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=1")?.audio
        XCTAssertEqual(audio?.verseRuns, .finite(1))
    }

    func testVerseRepeatUpperBoundIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=100")?.audio
        XCTAssertEqual(audio?.verseRuns, .finite(100))
    }

    func testVerseRepeatZeroIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&verse_repeat=0"))
    }

    func testVerseRepeatAboveUpperBoundIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&verse_repeat=101"))
    }

    func testVerseRepeatNegativeIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&verse_repeat=-1"))
    }

    func testVerseRepeatNonNumericIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&verse_repeat=abc"))
    }

    // MARK: - range_repeat

    func testRangeRepeatCountSetsFiniteRuns() {
        let audio = deepLink("quran://2/255?play=true&range_repeat=5")?.audio
        XCTAssertEqual(audio?.listRuns, .finite(5))
    }

    func testRangeRepeatInfiniteIsIndefinite() {
        let audio = deepLink("quran://2/255?play=true&range_repeat=infinite")?.audio
        XCTAssertEqual(audio?.listRuns, .indefinite)
    }

    func testRangeRepeatZeroIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&range_repeat=0"))
    }

    func testRangeRepeatAboveUpperBoundIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&range_repeat=101"))
    }

    func testRangeRepeatNonNumericIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&range_repeat=abc"))
    }

    func testVerseAndRangeRepeatAreIndependent() {
        let audio = deepLink("quran://2/255?play=true&verse_repeat=3&range_repeat=infinite")?.audio
        XCTAssertEqual(audio?.verseRuns, .finite(3))
        XCTAssertEqual(audio?.listRuns, .indefinite)
    }

    // MARK: - to (end of range)

    func testToSetsEndAyah() {
        let audio = deepLink("quran://2/255?play=true&to=2:257")?.audio
        XCTAssertEqual(audio?.end, ayah(sura: 2, ayah: 257))
    }

    func testToAbsentLeavesEndNil() {
        let audio = deepLink("quran://2/255?play=true")?.audio
        XCTAssertNil(audio?.end)
    }

    func testToInLaterSuraIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&to=3:5")?.audio
        XCTAssertEqual(audio?.end, ayah(sura: 3, ayah: 5))
    }

    func testToEqualToStartIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&to=2:255")?.audio
        XCTAssertEqual(audio?.end, ayah(sura: 2, ayah: 255))
    }

    func testToBeforeStartIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&to=2:100"))
    }

    func testToInEarlierSuraIsRejected() {
        XCTAssertNil(deepLink("quran://3/5?play=true&to=2:255"))
    }

    func testMalformedToIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&to=notasuraayah"))
        XCTAssertNil(deepLink("quran://2/255?play=true&to=2"))
        XCTAssertNil(deepLink("quran://2/255?play=true&to=2:"))
        XCTAssertNil(deepLink("quran://2/255?play=true&to=:5"))
        XCTAssertNil(deepLink("quran://2/255?play=true&to=2:255:3"))
    }

    func testToWithOutOfRangeSuraIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&to=200:5"))
    }

    func testToWithOutOfRangeAyahIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&to=2:999"))
    }

    func testToOnSuraOnlyLinkUsesFirstAyahAsStart() {
        let audio = deepLink("quran://2?play=true&to=2:10")?.audio
        XCTAssertEqual(audio?.end, ayah(sura: 2, ayah: 10))
    }

    func testToOnSuraOnlyLinkEqualToFirstAyahIsAccepted() {
        let audio = deepLink("quran://2?play=true&to=2:1")?.audio
        XCTAssertEqual(audio?.end, ayah(sura: 2, ayah: 1))
    }

    func testToOnSuraOnlyLinkInEarlierSuraIsRejected() {
        XCTAssertNil(deepLink("quran://3?play=true&to=2:255"))
    }

    // MARK: - reciter

    func testReciterIdIsParsed() {
        let audio = deepLink("quran://2/255?play=true&reciter=5")?.audio
        XCTAssertEqual(audio?.reciterId, 5)
    }

    func testReciterIdAbsentIsNil() {
        let audio = deepLink("quran://2/255?play=true")?.audio
        XCTAssertNil(audio?.reciterId)
    }

    func testReciterIdZeroIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&reciter=0"))
    }

    func testReciterIdNegativeIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&reciter=-3"))
    }

    func testReciterIdNonNumericIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&reciter=abc"))
    }

    // MARK: - speed

    func testPlaybackRateIsParsed() {
        let audio = deepLink("quran://2/255?play=true&speed=1.5")?.audio
        XCTAssertEqual(audio?.playbackRate, 1.5)
    }

    func testPlaybackRateAbsentIsNil() {
        let audio = deepLink("quran://2/255?play=true")?.audio
        XCTAssertNil(audio?.playbackRate)
    }

    func testPlaybackRateLowerBoundIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&speed=0.25")?.audio
        XCTAssertEqual(audio?.playbackRate, 0.25)
    }

    func testPlaybackRateUpperBoundIsAccepted() {
        let audio = deepLink("quran://2/255?play=true&speed=2.0")?.audio
        XCTAssertEqual(audio?.playbackRate, 2.0)
    }

    func testPlaybackRateBelowLowerBoundIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&speed=0.2"))
    }

    func testPlaybackRateAboveUpperBoundIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&speed=2.5"))
    }

    func testPlaybackRateNonNumericIsRejected() {
        XCTAssertNil(deepLink("quran://2/255?play=true&speed=fast"))
    }

    // MARK: - unknown parameters

    func testUnknownQueryParameterIsIgnored() {
        let link = deepLink("quran://2/255?foo=bar&play=true")
        XCTAssertEqual(link?.target, .ayah(ayah(sura: 2, ayah: 255)))
        XCTAssertEqual(link?.audio, defaultAudio())
    }

    // MARK: - full example

    func testFullExampleFromIssue() {
        let link = deepLink("quran://2/255?play=true&to=2:257&verse_repeat=3&range_repeat=infinite")
        XCTAssertEqual(link?.target, .ayah(ayah(sura: 2, ayah: 255)))
        XCTAssertEqual(link?.audio, QuranDeepLinkAudio(
            end: ayah(sura: 2, ayah: 257),
            verseRuns: .finite(3),
            listRuns: .indefinite,
            reciterId: nil,
            playbackRate: nil
        ))
    }

    // MARK: Private

    private let quran = Quran.hafsMadani1405

    private func deepLink(_ string: String) -> QuranDeepLink? {
        guard let url = URL(string: string) else {
            XCTFail("Couldn't create a URL out of \(string)")
            return nil
        }
        return QuranDeepLink(url: url, quran: quran)
    }

    private func sura(_ suraNumber: Int) -> Sura {
        Sura(quran: quran, suraNumber: suraNumber)!
    }

    private func ayah(sura suraNumber: Int, ayah ayahNumber: Int) -> AyahNumber {
        AyahNumber(quran: quran, sura: suraNumber, ayah: ayahNumber)!
    }

    private func defaultAudio() -> QuranDeepLinkAudio {
        QuranDeepLinkAudio(
            end: nil,
            verseRuns: .finite(1),
            listRuns: .finite(1),
            reciterId: nil,
            playbackRate: nil
        )
    }
}
