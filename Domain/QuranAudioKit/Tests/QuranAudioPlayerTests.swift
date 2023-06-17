//
//  QuranAudioPlayerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import AsyncUtilitiesForTesting
import AVFoundation
import QuranAudio
import QuranKit
import SnapshotTesting
import XCTest
@testable import QueuePlayer
@testable import QuranAudioKit

@MainActor
class QuranAudioPlayerTests: XCTestCase {
    private var player: QuranAudioPlayer!
    private var queuePlayer: QueuePlayerFake!
    private var delegate: QuranAudioPlayerDelegateClosures!

    private let quran = Quran.hafsMadani1405
    private let suras = Quran.hafsMadani1405.suras
    private let gappedReciter: Reciter = .gappedReciter
    private let gaplessReciter: Reciter = .gaplessReciter

    override func setUp() async throws {
        queuePlayer = QueuePlayerFake()
        delegate = QuranAudioPlayerDelegateClosures()

        player = QuranAudioPlayer(player: queuePlayer)
        player.setActions(delegate.makeActions())
    }

    override func tearDownWithError() throws {
        Reciter.cleanUpAudio()
    }

    func testPlayingDownloadedGaplessReciter1FullSura() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[0].firstVerse,
            to: suras[0].lastVerse,
            files: ["001.mp3"]
        )
    }

    func testPlayingDownloadedGaplessReciter1SuraEndsEarly() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[0].verses[1],
            to: suras[0].verses[4],
            files: ["001.mp3"]
        )
    }

    func testPlayingDownloadedGaplessReciter3FullSura() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[111].firstVerse,
            to: suras[113].lastVerse,
            files: ["112.mp3",
                    "113.mp3",
                    "114.mp3"]
        )
    }

    func testPlayingDownloadedGaplessReciter2Suras1stSuraHasEndTimestamp() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[76].verses[48],
            to: suras[77].verses[2],
            files: ["077.mp3",
                    "078.mp3"]
        )
    }

    func testPlayingDownloadedGaplessReciter1SurasHasEndTimestamp() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[76].verses[48],
            to: suras[76].lastVerse,
            files: ["077.mp3"]
        )
    }

    func testPlayingDownloadedGaplessReciter1SurasHasEndTimestampStopBeforeEnd() async throws {
        try await runDownloadedGaplessTestCase(
            from: suras[76].verses[48],
            to: suras[76].verses[48],
            files: ["077.mp3"]
        )
    }

    func testPlayingDownloadedGappedReciter1FullSura() async throws {
        try await runDownloadedGappedTestCase(
            from: suras[0].firstVerse,
            to: suras[0].lastVerse,
            files: [
                "001001.mp3",
                "001002.mp3",
                "001003.mp3",
                "001004.mp3",
                "001005.mp3",
                "001006.mp3",
                "001007.mp3",
            ]
        )
    }

    func testPlayingDownloadedGappedReciter1SuraEndsEarly() async throws {
        try await runDownloadedGappedTestCase(
            from: suras[0].verses[1],
            to: suras[0].verses[4],
            files: [
                "001001.mp3", // always downloads besmAllah
                "001002.mp3",
                "001003.mp3",
                "001004.mp3",
                "001005.mp3",
            ]
        )
    }

    func testPlayingDownloadedGappedReciter3FullSura() async throws {
        try await runDownloadedGappedTestCase(
            from: suras[111].firstVerse,
            to: suras[113].lastVerse,
            files: [
                "001001.mp3", // always downloads besmAllah
                "112001.mp3",
                "112002.mp3",
                "112003.mp3",
                "112004.mp3",
                "113001.mp3",
                "113002.mp3",
                "113003.mp3",
                "113004.mp3",
                "113005.mp3",
                "114001.mp3",
                "114002.mp3",
                "114003.mp3",
                "114004.mp3",
                "114005.mp3",
                "114006.mp3",
            ]
        )
    }

    func testPlayingDownloadedGappedReciterAtTawbah() async throws {
        try await runDownloadedGappedTestCase(
            from: suras[8].verses[0],
            to: suras[8].verses[2],
            files: [
                "001001.mp3", // always downloads besmAllah
                "009001.mp3",
                "009002.mp3",
                "009003.mp3",
            ]
        )
    }

    func testAudioPlaybackControls() async throws {
        for i in 0 ..< 2 {
            // play
            try await runDownloadedTestCase(gapless: i == 0)

            XCTAssertEqual(queuePlayer.location, 0)

            // step forward
            player.stepForward()
            XCTAssertEqual(queuePlayer.state.isPlaying, true)
            XCTAssertEqual(queuePlayer.location, 1)

            // pause
            player.pauseAudio()
            XCTAssertEqual(queuePlayer.state.isPaused, true)
            XCTAssertEqual(queuePlayer.location, 1)

            // resume
            player.resumeAudio()
            XCTAssertEqual(queuePlayer.state.isPlaying, true)
            XCTAssertEqual(queuePlayer.location, 1)

            // step backward
            player.stepBackward()
            XCTAssertEqual(queuePlayer.state.isPlaying, true)
            XCTAssertEqual(queuePlayer.location, 0)

            // stop
            player.stopAudio()
            XCTAssertEqual(queuePlayer.state.isStopped, true)
            XCTAssertEqual(queuePlayer.location, 0)
        }
    }

    func testRespondsToQueuePlayerDelegate() async throws {
        let frameChanges = [(file: 0, frame: 2), (file: 2, frame: 0)]
        for i in 0 ..< 2 {
            // play
            try await runDownloadedTestCase(gapless: i == 0)

            // pause
            queuePlayer.actions?.playbackRateChanged(0)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackPaused])

            // resume
            queuePlayer.actions?.playbackRateChanged(1)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackResumed])

            // frame update
            let playerItem = AVPlayerItem(url: FileManager.documentsURL)
            let frameChange = frameChanges[i]
            queuePlayer.actions?.audioFrameChanged(frameChange.file, frameChange.frame, playerItem)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaying(AyahNumber(quran: quran, sura: 1, ayah: 3)!)])

            // end playback
            queuePlayer.actions?.playbackEnded()
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackEnded])

            // cannot end playback again or change frame
            queuePlayer.actions?.playbackEnded()
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [])
        }
    }

    private func runDownloadedTestCase(gapless: Bool) async throws {
        if gapless {
            try await runDownloadedGaplessTestCase(
                from: suras[0].firstVerse,
                to: suras[0].lastVerse,
                files: ["001.mp3"],
                snaphot: false
            )
        } else {
            try await runDownloadedGappedTestCase(
                from: suras[0].firstVerse,
                to: suras[0].lastVerse,
                files: [
                    "001001.mp3",
                    "001002.mp3",
                    "001003.mp3",
                    "001004.mp3",
                    "001005.mp3",
                    "001006.mp3",
                    "001007.mp3",
                ],
                snaphot: false
            )
        }
    }

    private func runDownloadedGappedTestCase(
        from: AyahNumber,
        to: AyahNumber,
        files: [String],
        snaphot: Bool = true,
        testName: String = #function
    ) async throws {
        let reciter = gappedReciter

        // test playing audio for downloaded gapped reciter
        try await player.play(reciter: reciter, from: from, to: to, verseRuns: .one, listRuns: .one)

        if snaphot {
            let state = queuePlayer.state
            assertSnapshot(matching: state, as: .json, testName: testName)
        }
    }

    private func runDownloadedGaplessTestCase(
        from: AyahNumber,
        to: AyahNumber,
        files: [String],
        snaphot: Bool = true,
        testName: String = #function
    ) async throws {
        let reciter = gaplessReciter
        try reciter.prepareGaplessReciterForTests()

        // test playing audio for downloaded gapless reciter
        try await player.play(reciter: reciter, from: from, to: to, verseRuns: .one, listRuns: .one)

        if snaphot {
            let state = queuePlayer.state
            assertSnapshot(matching: state, as: .json, testName: testName)
        }
    }
}
