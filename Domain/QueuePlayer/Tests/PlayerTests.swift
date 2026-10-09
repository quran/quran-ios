//
//  PlayerTests.swift
//
//
//  Created by Mohamed Afifi on 2026-10-07.
//

import AVFoundation
import XCTest
@testable import QueuePlayer

@MainActor
final class PlayerTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        audioFiles = try SilentAudioFiles()
    }

    override func tearDown() async throws {
        try audioFiles?.removeAll()
        try await super.tearDown()
    }

    func test_duration_loadsInTheBackground() async throws {
        let url = try audioFiles.make(duration: 0.5)
        let player = Player(url: url)

        // Creating the player doesn't read the duration synchronously.
        XCTAssertNil(player.duration)

        await waitForDuration(of: player)
        XCTAssertEqual(try XCTUnwrap(player.duration), 0.5, accuracy: 0.01)
    }

    func test_duration_ofUnreadableFileLoadsAsZero() async {
        // Zero, like the synchronous `AVAsset.duration`, so playback moves past the file.
        let player = Player(url: audioFiles.directory.appendingPathComponent("missing.mp3"))

        await waitForDuration(of: player)
        XCTAssertEqual(player.duration, 0)
    }

    func test_secondsOfLoadedDuration_reportsANumericDuration() {
        let duration = CMTime(seconds: 1.5, preferredTimescale: 1000)
        XCTAssertEqual(Player.seconds(ofLoadedDuration: duration), 1.5)
    }

    func test_secondsOfLoadedDuration_reportsAFailedLoadAsZero() {
        XCTAssertEqual(Player.seconds(ofLoadedDuration: nil), 0)
    }

    func test_secondsOfLoadedDuration_reportsAnIndefiniteDurationAsZero() {
        // What `load(.duration)` returns, without throwing, when a server
        // answers the byte-range probe with anything but a 206.
        XCTAssertEqual(Player.seconds(ofLoadedDuration: .indefinite), 0)
    }

    func test_secondsOfLoadedDuration_reportsAnInvalidDurationAsZero() {
        XCTAssertEqual(Player.seconds(ofLoadedDuration: .invalid), 0)
    }

    // MARK: Private

    private var audioFiles: SilentAudioFiles!

    private func waitForDuration(of player: Player) async {
        let loaded = expectation(description: "Duration loaded")
        player.onDurationLoaded = { loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 5)
    }
}
