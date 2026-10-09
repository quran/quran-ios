//
//  QueuePlayerTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import AVFoundation
import QuranAudio
import XCTest
@testable import QueuePlayer

@MainActor
final class QueuePlayerTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        audioFiles = try SilentAudioFiles()
        actions = QueuePlayerActionsSpy()
        clock = VerseDelayClockFake()
        player = QueuePlayer(sleep: { [clock] in await clock?.sleep($0) })
        player.actions = actions.makeActions()
    }

    override func tearDown() async throws {
        player = nil
        try audioFiles?.removeAll()
        try await super.tearDown()
    }

    func test_play_endsFramesWithTheirFilesOnceDurationsLoad() async throws {
        let request = try makeGappedRequest()

        player.play(request: request, rate: 1)

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
    }

    func test_pause_beforeDurationLoadsHoldsTheFrameUntilResumed() async throws {
        let request = try makeGappedRequest()

        player.play(request: request, rate: 1)
        player.pause()

        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)
        // Longer than the 0.1 s frame, so a frame-end timer left running would have ended it.
        try await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0)])

        player.resume()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
    }

    func test_durationLoaded_reportsEachPlayingFilesDuration() async throws {
        let request = try makeGappedRequest(durations: [0.1, 0.15])

        player.play(request: request, rate: 1)

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.durationsLoaded.count, 2)
        XCTAssertEqual(actions.durationsLoaded[0], 0.1, accuracy: 0.01)
        XCTAssertEqual(actions.durationsLoaded[1], 0.15, accuracy: 0.01)
    }

    func test_reloadingAFile_reusesItsLoadedDuration() async throws {
        let request = try makeSingleFileRequest()
        player.play(request: request, rate: 1)
        player.pause()
        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)

        // Seeks within the same file, which builds a new player for it.
        player.stepForward()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(0, 1), .playbackEnded])
        XCTAssertEqual(try XCTUnwrap(actions.frameDurations[1]), 0.15, accuracy: 0.01)
        XCTAssertEqual(actions.durationsLoaded.count, 1)
    }

    func test_resume_afterChangingTheRateWhilePausedEndsTheFrameAtTheNewRate() async throws {
        let request = try makeGappedRequest(durations: [0.15, 0.15])

        // At this rate the frame takes 3 s of wall-clock time to end.
        player.play(request: request, rate: 0.05)
        player.pause()
        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)

        // Under 0.1 s at this rate; a frame end still timed for the old rate misses the timeout.
        player.setRate(2)
        player.resume()

        await fulfillment(of: [actions.playbackEnded], timeout: 2.5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
    }

    // MARK: - Frame End

    func test_fileEnd_endsAFrameWhoseEstimatedDurationRunsPastItsAudio() async throws {
        // 0.12 s of audio that AVFoundation estimates at 3.12 s.
        let url = try audioFiles.makeMP3(duration: 0.12, trailingBytes: 48000)
        let request = try makeGappedRequest(firstFile: url)

        player.play(request: request, rate: 1)
        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)
        XCTAssertGreaterThan(try XCTUnwrap(actions.durationsLoaded.first), 3)
        // Without the file end, the frame-end timer waits 3.12 s and then stalls.
        try postEndOfFirstFile()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
    }

    func test_fileEnd_afterTheTimerEndedTheFrameDoesNotEndItAgain() async throws {
        let request = try makeGappedRequest(verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()
        try postEndOfFirstFile()

        // Ending the frame again would cut the delay short or wait out a second one.
        XCTAssertEqual(actions.events, [.frameChanged(0, 0)])
        clock.elapseAll()
        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
        XCTAssertEqual(clock.delays.count, 1)
    }

    func test_fileEnd_beforeTheDurationLoadsEndsTheFrameOnce() async throws {
        let request = try makeRepeatedRequest()

        player.play(request: request, rate: 1)
        try postEndOfFirstFile()
        await waitForVerseDelay()
        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)

        try await assertTheFirstRunEndedOnce()
    }

    func test_fileEnd_beforeTheFrameEndTimerEndsTheFrameOnce() async throws {
        let request = try makeRepeatedRequest()

        player.play(request: request, rate: 1)
        await fulfillment(of: [actions.firstDurationLoaded], timeout: 5)
        try postEndOfFirstFile()
        await waitForVerseDelay()

        try await assertTheFirstRunEndedOnce()
    }

    // MARK: - Asset Reuse

    func test_stepForward_withinAFileReusesItsAsset() async throws {
        let request = try makeSingleFileRequest()

        player.play(request: request, rate: 1)
        player.stepForward()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(0, 1), .playbackEnded])
        XCTAssertTrue(actions.playerItems[0].asset === actions.playerItems[1].asset)
    }

    func test_movingToAnotherFile_usesANewAsset() async throws {
        let request = try makeGappedRequest()

        player.play(request: request, rate: 1)

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
        XCTAssertFalse(actions.playerItems[0].asset === actions.playerItems[1].asset)
    }

    // MARK: - Verse Delay

    func test_resume_afterPausingDuringAVerseDelayPlaysTheNextVerse() async throws {
        let request = try makeGappedRequest(verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()
        player.pause()

        // The delay's time passing while paused doesn't advance playback.
        clock.elapse()
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0)])

        player.resume()
        clock.elapseAll()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
        // Resuming waits out only what was left of the delay.
        XCTAssertEqual(clock.delays.count, 2)
        if let delay = clock.delays.first, let remainingDelay = clock.delays.last {
            XCTAssertLessThan(remainingDelay, delay)
        }
    }

    func test_stepForward_duringAVerseDelayDoesNotReplayTheVerse() async throws {
        let request = try makeGappedRequest(durations: [0.1, 0.1, 0.1], verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()
        player.stepForward()
        // Includes the delay that was pending when stepping.
        clock.elapseAll()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .frameChanged(2, 0), .playbackEnded])
    }

    func test_stepBackward_duringAVerseDelayDoesNotJumpAhead() async throws {
        let request = try makeGappedRequest(durations: [0.1, 0.1, 0.1], verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()
        clock.elapse()
        await waitForVerseDelay()
        player.stepBackward()
        // Includes the delay that was pending when stepping.
        clock.elapseAll()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [
            .frameChanged(0, 0), .frameChanged(1, 0),
            .frameChanged(0, 0), .frameChanged(1, 0), .frameChanged(2, 0),
            .playbackEnded,
        ])
    }

    func test_stepForward_duringAVerseDelayReportsThatPlaybackResumed() async throws {
        let request = try makeGappedRequest(verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()

        let resumed = expectation(description: "Playback resumed")
        actions.onRateChanged = { [weak actions] rate in
            guard rate > 0 else {
                return
            }
            actions?.onRateChanged = nil
            resumed.fulfill()
        }
        player.stepForward()

        await fulfillment(of: [resumed], timeout: 5)
    }

    func test_pause_duringAVerseDelayReportsThatPlaybackPaused() async throws {
        let request = try makeGappedRequest(verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()

        let paused = expectation(description: "Playback paused")
        actions.onRateChanged = { [weak actions] rate in
            guard rate == 0 else {
                return
            }
            actions?.onRateChanged = nil
            paused.fulfill()
        }
        player.pause()

        await fulfillment(of: [paused], timeout: 5)
    }

    func test_resume_duringAVerseDelayReportsThatPlaybackResumed() async throws {
        let request = try makeGappedRequest(verseDelay: .full)

        player.play(request: request, rate: 1)
        await waitForVerseDelay()
        player.pause()

        let resumed = expectation(description: "Playback resumed")
        actions.onRateChanged = { [weak actions] rate in
            guard rate > 0 else {
                return
            }
            actions?.onRateChanged = nil
            resumed.fulfill()
        }
        // The rest of the delay stays pending, so the report comes before the next verse plays.
        player.resume()

        await fulfillment(of: [resumed], timeout: 5)
    }

    // MARK: Private

    private var audioFiles: SilentAudioFiles!
    private var actions: QueuePlayerActionsSpy!
    private var clock: VerseDelayClockFake!
    private var player: QueuePlayer!

    /// Like a gapped reciter's request: every frame ends with its file. Durations stay under the
    /// 200 ms frame-end tolerance, so frames end even where the simulator doesn't advance playback.
    private func makeGappedRequest(
        durations: [TimeInterval] = [0.1, 0.1],
        requestRuns: Runs = .finite(1),
        verseDelay: VerseDelay = .none,
        repetitionDelay: RepetitionDelay = .none
    ) throws -> AudioRequest {
        let files = try durations.map { duration in
            let url = try audioFiles.make(duration: duration)
            return AudioFile(url: url, frames: [AudioFrame(startTime: 0, endTime: nil)])
        }
        return AudioRequest(
            files: files,
            endTime: nil,
            frameRuns: .finite(1),
            requestRuns: requestRuns,
            verseDelay: verseDelay,
            repetitionDelay: repetitionDelay
        )
    }

    /// A gapped request whose first frame plays `firstFile`, followed by a 0.1 s file.
    private func makeGappedRequest(firstFile: URL) throws -> AudioRequest {
        let files = try [firstFile, audioFiles.make(duration: 0.1)].map { url in
            AudioFile(url: url, frames: [AudioFrame(startTime: 0, endTime: nil)])
        }
        return AudioRequest(files: files, endTime: nil, frameRuns: .finite(1), requestRuns: .finite(1))
    }

    /// Like a gapless reciter's sura: two frames in one 0.15 s file, the last ending with the file.
    private func makeSingleFileRequest() throws -> AudioRequest {
        let url = try audioFiles.make(duration: 0.15)
        let frames = [AudioFrame(startTime: 0, endTime: 0.05), AudioFrame(startTime: 0.05, endTime: nil)]
        return AudioRequest(files: [AudioFile(url: url, frames: frames)], endTime: nil, frameRuns: .finite(1), requestRuns: .finite(1))
    }

    /// A 0.1 s gapped file played twice, with a delay between the runs that keeps the first run's player.
    private func makeRepeatedRequest() throws -> AudioRequest {
        try makeGappedRequest(durations: [0.1], requestRuns: .finite(2), repetitionDelay: .oneSecond)
    }

    /// Posts the first file's end-of-item notification, since the simulator may not play the audio.
    private func postEndOfFirstFile() throws {
        let item = try XCTUnwrap(actions.playerItems.first)
        NotificationCenter.default.post(name: AVPlayerItem.didPlayToEndTimeNotification, object: item)
    }

    /// Expects the first run, now waiting out its delay, to have ended only once.
    private func assertTheFirstRunEndedOnce() async throws {
        // Longer than the 0.1 s frame, so a frame-end timer left running would have ended it again.
        try await Task.sleep(nanoseconds: 300_000_000)

        clock.elapseAll()
        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(0, 0), .playbackEnded])
        XCTAssertEqual(clock.delays, [1])
    }

    /// Waits until a verse ends and the player starts waiting out the delay after it.
    private func waitForVerseDelay() async {
        let started = expectation(description: "Verse delay started")
        clock.onNextDelay = { started.fulfill() }
        await fulfillment(of: [started], timeout: 5)
    }
}

/// Holds each between-verse delay until the test lets it elapse.
@MainActor
private final class VerseDelayClockFake {
    // MARK: Internal

    /// Every delay the player waited out, in seconds.
    private(set) var delays: [TimeInterval] = []
    var onNextDelay: (() -> Void)?

    func sleep(_ delay: TimeInterval) async {
        delays.append(delay)
        guard !elapsesImmediately else {
            return
        }
        await withCheckedContinuation { continuation in
            pending.append(continuation)
            let onNextDelay = onNextDelay
            self.onNextDelay = nil
            onNextDelay?()
        }
    }

    /// Lets the pending delays elapse.
    func elapse() {
        let pending = pending
        self.pending = []
        pending.forEach { $0.resume() }
    }

    /// Lets the pending delays, and every later one, elapse.
    func elapseAll() {
        elapsesImmediately = true
        elapse()
    }

    // MARK: Private

    private var pending: [CheckedContinuation<Void, Never>] = []
    private var elapsesImmediately = false
}

@MainActor
private final class QueuePlayerActionsSpy {
    enum Event: Equatable {
        case frameChanged(Int, Int)
        case playbackEnded
    }

    let playbackEnded = XCTestExpectation(description: "Playback ended")
    let firstDurationLoaded = XCTestExpectation(description: "First duration loaded")
    private(set) var events: [Event] = []
    private(set) var durationsLoaded: [TimeInterval] = []
    /// The duration each `audioFrameChanged` carried, in order.
    private(set) var frameDurations: [TimeInterval?] = []
    /// The player item each `audioFrameChanged` carried, in order.
    private(set) var playerItems: [AVPlayerItem] = []
    var onRateChanged: ((Float) -> Void)?

    func makeActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.events.append(.playbackEnded)
                self?.playbackEnded.fulfill()
            },
            playbackRateChanged: { [weak self] in
                self?.onRateChanged?($0)
            },
            audioFrameChanged: { [weak self] fileIndex, frameIndex, playerItem, duration in
                self?.events.append(.frameChanged(fileIndex, frameIndex))
                self?.frameDurations.append(duration)
                self?.playerItems.append(playerItem)
            },
            durationLoaded: { [weak self] in
                self?.durationsLoaded.append($0)
                if self?.durationsLoaded.count == 1 {
                    self?.firstDurationLoaded.fulfill()
                }
            }
        )
    }
}
