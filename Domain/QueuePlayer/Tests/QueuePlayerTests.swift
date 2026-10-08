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

        // Long enough for the duration to load and the frame to end, were it not paused.
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0)])

        player.resume()

        await fulfillment(of: [actions.playbackEnded], timeout: 5)
        XCTAssertEqual(actions.events, [.frameChanged(0, 0), .frameChanged(1, 0), .playbackEnded])
    }

    // MARK: Private

    private var audioFiles: SilentAudioFiles!
    private var actions: QueuePlayerActionsSpy!
    private var player: QueuePlayer!

    /// Like a gapped reciter's request: every frame ends with its file, so its end
    /// comes from the file's duration.
    private func makeGappedRequest() throws -> AudioRequest {
        let files = try (0 ..< 2).map { _ in
            // Shorter than the 200 ms frame-end tolerance, so frames end even where
            // the simulator doesn't advance playback.
            let url = try audioFiles.make(duration: 0.1)
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
    private(set) var events: [Event] = []

    func makeActions() -> QueuePlayerActions {
        QueuePlayerActions(
            playbackEnded: { [weak self] in
                self?.events.append(.playbackEnded)
                self?.playbackEnded.fulfill()
            },
            playbackRateChanged: { _ in },
            audioFrameChanged: { [weak self] fileIndex, frameIndex, _ in
                self?.events.append(.frameChanged(fileIndex, frameIndex))
            }
        )
    }
}
