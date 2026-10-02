//
//  AudioPlaybackViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

import Localization
import QueuePlayer
import QuranAudio
import QuranAudioKit
import ReciterListFeature
import ReciterService
import ReciterServiceFake
import SystemDependenciesFake
import UIKit
import XCTest
@testable import SettingsFeature

@MainActor
final class AudioPlaybackViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        saved = SavedPreferences()
    }

    override func tearDown() async throws {
        saved.restore()
        try await super.tearDown()
    }

    // MARK: Saving

    func test_playbackSpeed_savesThePreference() {
        audioPreferences.playbackRate = 1
        let sut = makeSUT()

        sut.playbackRate = 1.5

        XCTAssertEqual(audioPreferences.playbackRate, 1.5)
    }

    func test_playUpTo_savesThePreference() {
        audioPreferences.audioEnd = .juz
        let sut = makeSUT()

        sut.audioEnd = .page

        XCTAssertEqual(audioPreferences.audioEnd, .page)
    }

    func test_playUpTo_savesQuarterAndHizb() {
        audioPreferences.audioEnd = .juz
        let sut = makeSUT()

        sut.audioEnd = .quarter
        XCTAssertEqual(audioPreferences.audioEnd, .quarter)

        sut.audioEnd = .hizb
        XCTAssertEqual(audioPreferences.audioEnd, .hizb)
    }

    func test_streamAudio_savesThePreference() {
        audioPreferences.streamingEnabled = false
        let sut = makeSUT()

        sut.streamingEnabled = true

        XCTAssertTrue(audioPreferences.streamingEnabled)
    }

    func test_playEachVerse_savesRepeatCountAndPause() {
        audioPreferences.verseRuns = .finite(1)
        audioPreferences.verseDelay = .none
        let sut = makeSUT()

        sut.verseRuns = .indefinite
        sut.verseDelay = .full

        XCTAssertEqual(audioPreferences.verseRuns, .indefinite)
        XCTAssertEqual(audioPreferences.verseDelay, .full)
    }

    func test_playSetOfVerses_savesRepeatCountAndPause() {
        audioPreferences.listRuns = .finite(1)
        audioPreferences.repetitionDelay = .oneSecond
        let sut = makeSUT()

        sut.listRuns = .finite(3)
        sut.repetitionDelay = .fiveSeconds

        XCTAssertEqual(audioPreferences.listRuns, .finite(3))
        XCTAssertEqual(audioPreferences.repetitionDelay, .fiveSeconds)
    }

    // MARK: Footer

    func test_playbackFooter_followsPlayUpTo() {
        let sut = makeSUT()
        let expectedKeys: [AudioEnd: String] = [
            .page: "audio.playback.footer.page",
            .quarter: "audio.playback.footer.quarter",
            .hizb: "audio.playback.footer.hizb",
            .sura: "audio.playback.footer.surah",
            .juz: "audio.playback.footer.juz",
            .quran: "audio.playback.footer.quran",
        ]

        for audioEnd in AudioEnd.playUpToChoices {
            sut.audioEnd = audioEnd

            XCTAssertEqual(sut.playbackFooter, l(expectedKeys[audioEnd]!), "\(audioEnd)")
        }
    }

    // MARK: Live updates

    func test_values_followPreferenceChangesMadeElsewhere() {
        audioPreferences.playbackRate = 1
        audioPreferences.audioEnd = .juz
        audioPreferences.streamingEnabled = false
        audioPreferences.verseRuns = .finite(1)
        audioPreferences.verseDelay = .none
        audioPreferences.listRuns = .finite(1)
        audioPreferences.repetitionDelay = .oneSecond
        let sut = makeSUT()

        audioPreferences.playbackRate = 0.75
        audioPreferences.audioEnd = .quran
        audioPreferences.streamingEnabled = true
        audioPreferences.verseRuns = .finite(2)
        audioPreferences.verseDelay = .double
        audioPreferences.listRuns = .indefinite
        audioPreferences.repetitionDelay = .tenSeconds

        XCTAssertEqual(sut.playbackRate, 0.75)
        XCTAssertEqual(sut.audioEnd, .quran)
        XCTAssertTrue(sut.streamingEnabled)
        XCTAssertEqual(sut.verseRuns, .finite(2))
        XCTAssertEqual(sut.verseDelay, .double)
        XCTAssertEqual(sut.listRuns, .indefinite)
        XCTAssertEqual(sut.repetitionDelay, .tenSeconds)
    }

    // MARK: Reciter

    func test_reciter_isTheSavedReciter() async {
        reciterPreferences.lastSelectedReciterId = Reciter.gaplessReciter.id
        let sut = makeSUT()

        await sut.start()

        XCTAssertEqual(sut.reciter, .gaplessReciter)
    }

    func test_reciter_fallsBackToTheFirstReciter_whenTheSavedOneIsMissing() async {
        reciterPreferences.lastSelectedReciterId = 999
        let sut = makeSUT()

        await sut.start()

        XCTAssertNotNil(sut.reciter)
        XCTAssertEqual(sut.reciter, sut.reciters.first)
    }

    func test_selectingReciter_savesItAndAddsItToRecents() async {
        reciterPreferences.lastSelectedReciterId = Reciter.gappedReciter.id
        reciterPreferences.recentReciterIds = [Reciter.gappedReciter.id]
        let sut = makeSUT()
        await sut.start()

        sut.onSelectedReciterChanged(to: .gaplessReciter)

        XCTAssertEqual(reciterPreferences.lastSelectedReciterId, Reciter.gaplessReciter.id)
        XCTAssertEqual(Array(reciterPreferences.recentReciterIds), [Reciter.gappedReciter.id, Reciter.gaplessReciter.id])
        XCTAssertEqual(sut.reciter, .gaplessReciter)
    }

    // MARK: Private

    private var saved: SavedPreferences!

    private let audioPreferences = AudioPreferences.shared
    private let reciterPreferences = ReciterPreferences.shared

    private func makeSUT() -> AudioPlaybackViewModel {
        let bundle = SystemBundleFake()
        bundle.arrays = [
            "reciters.plist": [Reciter.gappedReciter, .gaplessReciter].map { $0.toPlistDictionary() } as NSArray,
        ]
        return AudioPlaybackViewModel(
            reciterRetriever: ReciterDataRetriever(bundle: bundle),
            recentRecitersService: RecentRecitersService(),
            reciterListBuilder: ReciterListBuilder(),
            navigationController: UINavigationController()
        )
    }
}

/// The audio preferences live in the shared user defaults; tests put them back.
@MainActor
private struct SavedPreferences {
    // MARK: Lifecycle

    init() {
        let audio = AudioPreferences.shared
        playbackRate = audio.playbackRate
        audioEnd = audio.audioEnd
        streamingEnabled = audio.streamingEnabled
        verseRuns = audio.verseRuns
        verseDelay = audio.verseDelay
        listRuns = audio.listRuns
        repetitionDelay = audio.repetitionDelay
        lastSelectedReciterId = ReciterPreferences.shared.lastSelectedReciterId
        let recentReciterIds = ReciterPreferences.shared.recentReciterIds
        restoreRecentReciters = { ReciterPreferences.shared.recentReciterIds = recentReciterIds }
    }

    // MARK: Internal

    func restore() {
        let audio = AudioPreferences.shared
        audio.playbackRate = playbackRate
        audio.audioEnd = audioEnd
        audio.streamingEnabled = streamingEnabled
        audio.verseRuns = verseRuns
        audio.verseDelay = verseDelay
        audio.listRuns = listRuns
        audio.repetitionDelay = repetitionDelay
        ReciterPreferences.shared.lastSelectedReciterId = lastSelectedReciterId
        restoreRecentReciters()
    }

    // MARK: Private

    private let playbackRate: Float
    private let audioEnd: AudioEnd
    private let streamingEnabled: Bool
    private let verseRuns: Runs
    private let verseDelay: VerseDelay
    private let listRuns: Runs
    private let repetitionDelay: RepetitionDelay
    private let lastSelectedReciterId: Int
    private let restoreRecentReciters: () -> Void
}
