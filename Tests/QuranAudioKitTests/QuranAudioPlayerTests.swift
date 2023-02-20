//
//  QuranAudioPlayerTests.swift
//
//
//  Created by Mohamed Afifi on 2022-02-08.
//

import AVFoundation
@testable import BatchDownloader
import QueuePlayer
@testable import QuranAudioKit
import QuranKit
import SnapshotTesting
import TestUtilities
import XCTest

class QuranAudioPlayerTests: XCTestCase {
    private var player: QuranAudioPlayer!
    private var downloader: DownloadManagerFake!
    private var queuePlayer: QueuePlayerFake!
    private var fileSystem: FileSystemFake!
    private var delegate: QuranAudioPlayerDelegateClosures!

    private let suras = Quran.madani.suras
    private static let baseURL = URL(validURL: "http://example.com")
    let request = DownloadRequest(url: baseURL.appendingPathComponent("mishari_alafasy/001.mp3"),
                                  destinationPath: "audio_files/mishari_alafasy/001.mp3")
    private let gappedReciter: Reciter = .gappedReciter
    private let gaplessReciter: Reciter = .gaplessReciter

    override func setUpWithError() throws {
        downloader = DownloadManagerFake()
        queuePlayer = QueuePlayerFake()
        fileSystem = FileSystemFake()
        delegate = QuranAudioPlayerDelegateClosures()

        player = QuranAudioPlayer(
            baseURL: Self.baseURL,
            downloadManager: downloader,
            player: queuePlayer,
            fileSystem: fileSystem
        )
        player.delegate = delegate
    }

    override func tearDownWithError() throws {
        let audioDirectory = FileManager.documentsURL.appendingPathComponent(Files.audioFilesPathComponent)
        if audioDirectory.isReachable {
            try FileManager.default.removeItem(at: audioDirectory)
        }
    }

    func testPlayingDownloadedGaplessReciter1FullSura() throws {
        try runDownloadedGaplessTestCase(from: suras[0].firstVerse,
                                         to: suras[0].lastVerse,
                                         files: ["001.mp3"])
    }

    func testPlayingDownloadedGaplessReciter1SuraEndsEarly() throws {
        try runDownloadedGaplessTestCase(from: suras[0].verses[1],
                                         to: suras[0].verses[4],
                                         files: ["001.mp3"])
    }

    func testPlayingDownloadedGaplessReciter3FullSura() throws {
        try runDownloadedGaplessTestCase(from: suras[111].firstVerse,
                                         to: suras[113].lastVerse,
                                         files: ["112.mp3",
                                                 "113.mp3",
                                                 "114.mp3"])
    }

    func testPlayingDownloadedGaplessReciter2Suras1stSuraHasEndTimestamp() throws {
        try runDownloadedGaplessTestCase(from: suras[76].verses[48],
                                         to: suras[77].verses[2],
                                         files: ["077.mp3",
                                                 "078.mp3"])
    }

    func testPlayingDownloadedGaplessReciter1SurasHasEndTimestamp() throws {
        try runDownloadedGaplessTestCase(from: suras[76].verses[48],
                                         to: suras[76].lastVerse,
                                         files: ["077.mp3"])
    }

    func testPlayingDownloadedGaplessReciter1SurasHasEndTimestampStopBeforeEnd() throws {
        try runDownloadedGaplessTestCase(from: suras[76].verses[48],
                                         to: suras[76].verses[48],
                                         files: ["077.mp3"])
    }

    func testPlayingDownloadedGappedReciter1FullSura() throws {
        try runDownloadedGappedTestCase(from: suras[0].firstVerse,
                                        to: suras[0].lastVerse,
                                        files: [
                                            "001001.mp3",
                                            "001002.mp3",
                                            "001003.mp3",
                                            "001004.mp3",
                                            "001005.mp3",
                                            "001006.mp3",
                                            "001007.mp3",
                                        ])
    }

    func testPlayingDownloadedGappedReciter1SuraEndsEarly() throws {
        try runDownloadedGappedTestCase(from: suras[0].verses[1],
                                        to: suras[0].verses[4],
                                        files: [
                                            "001001.mp3", // always downloads besmAllah
                                            "001002.mp3",
                                            "001003.mp3",
                                            "001004.mp3",
                                            "001005.mp3",
                                        ])
    }

    func testPlayingDownloadedGappedReciter3FullSura() throws {
        try runDownloadedGappedTestCase(from: suras[111].firstVerse,
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
                                        ])
    }

    func testPlayingDownloadedGappedReciterAtTawbah() throws {
        try runDownloadedGappedTestCase(from: suras[8].verses[0],
                                        to: suras[8].verses[2],
                                        files: [
                                            "001001.mp3", // always downloads besmAllah
                                            "009001.mp3",
                                            "009002.mp3",
                                            "009003.mp3",
                                        ])
    }

    func testAudioPlaybackControls() throws {
        for i in 0 ..< 2 {
            // play
            try runDownloadedTestCase(gapless: i == 0)

            XCTAssertEqual(queuePlayer.location, 0)

            // step forward
            player.stepForward()
            XCTAssertTrue(queuePlayer.state.isPlaying)
            XCTAssertEqual(queuePlayer.location, 1)

            // pause
            player.pauseAudio()
            XCTAssertTrue(queuePlayer.state.isPaused)
            XCTAssertEqual(queuePlayer.location, 1)

            // resume
            player.resumeAudio()
            XCTAssertTrue(queuePlayer.state.isPlaying)
            XCTAssertEqual(queuePlayer.location, 1)

            // step backward
            player.stepBackward()
            XCTAssertTrue(queuePlayer.state.isPlaying)
            XCTAssertEqual(queuePlayer.location, 0)

            // stop
            player.stopAudio()
            XCTAssertTrue(queuePlayer.state.isStopped)
            XCTAssertEqual(queuePlayer.location, 0)
        }
    }

    func testRespondsToQueuePlayerDelegate() throws {
        let frameChanges = [(file: 0, frame: 2), (file: 2, frame: 0)]
        for i in 0 ..< 2 {
            // play
            try runDownloadedTestCase(gapless: i == 0)

            // pause
            queuePlayer.delegate?.onPlaybackRateChanged(rate: 0)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackPaused])

            // resume
            queuePlayer.delegate?.onPlaybackRateChanged(rate: 1)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackResumed])

            // frame update
            let playerItem = AVPlayerItem(url: FileManager.documentsURL)
            let frameChange = frameChanges[i]
            queuePlayer.delegate?.onAudioFrameChanged(fileIndex: frameChange.file, frameIndex: frameChange.frame, playerItem: playerItem)
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaying(AyahNumber(quran: .madani, sura: 1, ayah: 3)!)])

            // end playback
            queuePlayer.delegate?.onPlaybackEnded()
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackOrDownloadingCompleted])

            // cannot end playback again or change frame
            queuePlayer.delegate?.onPlaybackEnded()
            XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [])
        }
    }

    func testDownloadFirstBeforePlaying() throws {
        try gaplessReciter.prepareGaplessReciterForTests()

        // start downloading
        let response = startDownloadingGaplessAudio()

        // complete the download
        response.fulfill()

        waitForPlayingToStart()
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlayingStarted])
        assertSnapshot(matching: queuePlayer.state, as: .json)
    }

    func testDownloadingFailedInTheMiddle() throws {
        try gaplessReciter.prepareGaplessReciterForTests()

        // start downloading
        let response = startDownloadingGaplessAudio()

        // fail the download
        response.reject(URLError(.timedOut))
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [])

        waitForDelegateMethod { done in
            delegate.onPlaybackOrDownloadingCompletedBlock = done
        }
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackOrDownloadingCompleted, .onFailedDownloading])
        XCTAssertEqual(queuePlayer.state, .stopped)
    }

    func testDownloadingThenCanceling() throws {
        try gaplessReciter.prepareGaplessReciterForTests()

        // start downloading
        let response = startDownloadingGaplessAudio()

        // cancel the download
        player.cancelDownload()
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackOrDownloadingCompleted])

        // fail the download
        response.reject(URLError(.timedOut))

        wait(for: DispatchQueue.main)

        // TODO: this is wrong. The delegate should produce any more events
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackOrDownloadingCompleted, .onFailedDownloading])
        XCTAssertEqual(queuePlayer.state, .stopped)
    }

    func testStartingWithNoDownloadInProgress() throws {
        let result = try wait(for: player.isAudioDownloading())
        XCTAssertFalse(result)
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [])
    }

    func testStartingDownloadInProgress() throws {
        let childResponse = DownloadResponse(download: Download(request: request, batchId: 1), progress: QProgress(totalUnitCount: 1))
        let response = DownloadBatchResponse(batchId: 1, responses: [childResponse], cancellable: nil)
        downloader.downloads = [response]

        // download should be in progress
        let result = try wait(for: player.isAudioDownloading())
        XCTAssertTrue(result)
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.didStartDownloadingAudioFiles])

        // end the download
        response.fulfill()
        waitForDelegateMethod { done in
            delegate.onPlaybackOrDownloadingCompletedBlock = done
        }
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlaybackOrDownloadingCompleted])
    }

    private func startDownloadingGaplessAudio() -> DownloadBatchResponse {
        let response = DownloadBatchResponse(batchId: 1, responses: [], cancellable: nil)
        downloader.responses[DownloadBatchRequest(requests: [request])] = response

        player.playAudioForReciter(gaplessReciter,
                                   from: suras[0].firstVerse,
                                   to: suras[0].lastVerse)
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.willStartDownloading])

        // did start downloading
        waitForDelegateMethod { done in
            delegate.didStartDownloadingAudioFiles = { _ in done() }
        }
        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.didStartDownloadingAudioFiles])

        return response
    }

    private func runDownloadedTestCase(gapless: Bool) throws {
        fileSystem.checkedFiles = []
        if gapless {
            try runDownloadedGaplessTestCase(from: suras[0].firstVerse,
                                             to: suras[0].lastVerse,
                                             files: ["001.mp3"],
                                             snaphot: false)
        } else {
            try runDownloadedGappedTestCase(from: suras[0].firstVerse,
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
                                            snaphot: false)
        }
    }

    private func runDownloadedGappedTestCase(from: AyahNumber,
                                             to: AyahNumber,
                                             files: [String],
                                             snaphot: Bool = true,
                                             testName: String = #function) throws
    {
        let reciter = gappedReciter
        let directory = reciter.localFolder()
        let reciterFiles = files.map { directory.appendingPathComponent($0) }
        let reciterFilesSet = Set(reciterFiles)
        fileSystem.files = reciterFilesSet

        // test playing audio for downloaded gapless reciter
        player.playAudioForReciter(reciter, from: from, to: to)

        // assert that files checked are the one expected
        XCTAssertEqual(fileSystem.checkedFiles, reciterFilesSet)

        waitForPlayingToStart()

        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlayingStarted])
        if snaphot {
            assertSnapshot(matching: queuePlayer.state, as: .json, testName: testName)
        }
    }

    private func runDownloadedGaplessTestCase(from: AyahNumber,
                                              to: AyahNumber,
                                              files: [String],
                                              snaphot: Bool = true,
                                              testName: String = #function) throws
    {
        let reciter = gaplessReciter
        try reciter.prepareGaplessReciterForTests()
        let directory = reciter.localFolder()
        let reciterFiles = (files + [reciter.gaplessDatabaseZip])
            .compactMap { directory.appendingPathComponent($0) }
        let reciterFilesSet = Set(reciterFiles)
        fileSystem.files = reciterFilesSet

        // test playing audio for downloaded gapless reciter
        player.playAudioForReciter(reciter, from: from, to: to)

        // assert that files checked are the one expected
        XCTAssertEqual(fileSystem.checkedFiles, reciterFilesSet)

        waitForPlayingToStart()

        XCTAssertEqual(delegate.eventsDiffSinceLastCalled, [.onPlayingStarted])
        if snaphot {
            assertSnapshot(matching: queuePlayer.state, as: .json, testName: testName)
        }
    }

    private func waitForPlayingToStart(timeout: TimeInterval = 1) {
        waitForDelegateMethod(timeout: timeout) { done in
            delegate.onPlayingStartedBlock = { done() }
        }
    }

    private func waitForDelegateMethod(timeout: TimeInterval = 1, block: (@escaping () -> Void) -> Void) {
        let delegateExpectation = expectation(description: "delegate")
        block(delegateExpectation.fulfill)
        wait(for: [delegateExpectation], timeout: timeout)
    }
}
