//
//  QueuePlayerTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

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
        player = QueuePlayer()
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

    func test_durationLoaded_ignoresAReplacedPlayersFile() async throws {
        let request = try makeGappedRequest(durations: [0.1, 0.15])

        player.play(request: request, rate: 1)
        // Replaces the first file's player before its duration loads.
        player.stepForward()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.durationsLoaded.count, 1)
        XCTAssertEqual(actions.durationsLoaded[0], 0.15, accuracy: 0.01)
    }

    // MARK: Private

    private var audioFiles: SilentAudioFiles!
    private var actions: QueuePlayerActionsSpy!
    private var player: QueuePlayer!

    /// Like a gapped reciter's request: every frame ends with its file, so its end
    /// comes from the file's duration.
    /// Durations stay shorter than the 200 ms frame-end tolerance, so frames end
    /// even where the simulator doesn't advance playback.
    private func makeGappedRequest(durations: [TimeInterval] = [0.1, 0.1]) throws -> AudioRequest {
        let files = try durations.map { duration in
            let url = try audioFiles.make(duration: duration)
            return AudioFile(url: url, frames: [AudioFrame(startTime: 0, endTime: nil)])
        }
        return AudioRequest(files: files, endTime: nil, frameRuns: .finite(1), requestRuns: .finite(1))
    }
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

    func makeActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.events.append(.playbackEnded)
                self?.playbackEnded.fulfill()
            },
            playbackRateChanged: { _ in },
            audioFrameChanged: { [weak self] fileIndex, frameIndex, _, _ in
                self?.events.append(.frameChanged(fileIndex, frameIndex))
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
