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
        let player = Player(asset: PlayerAsset(url: url))

        XCTAssertNil(player.duration)

        await waitForDuration(of: player)
        XCTAssertEqual(try XCTUnwrap(player.duration), 0.5, accuracy: 0.01)
    }

    func test_duration_ofUnreadableFileLoadsAsZero() async {
        let player = Player(asset: PlayerAsset(url: audioFiles.directory.appendingPathComponent("missing.mp3")))

        await waitForDuration(of: player)
        XCTAssertEqual(player.duration, 0)
    }

    func test_releasingAPlayerOfASharedRemoteAsset_keepsTheOtherPlayersLoadGoing() async throws {
        let loader = PendingResourceLoader()
        var replaced: Player? = try Player(asset: makePendingRemoteAsset(loader: loader))
        let current = try Player(asset: XCTUnwrap(replaced).asset)
        await fulfillment(of: [loader.requested], timeout: 5)

        // Cancelling the shared asset's load would report a zero duration to `current`.
        replaced = nil
        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertNil(current.duration)
    }

    func test_releasingTheLastPlayerOfARemoteAsset_stopsItsLoad() async throws {
        let loader = PendingResourceLoader()
        var player: Player? = try Player(asset: makePendingRemoteAsset(loader: loader))
        await fulfillment(of: [loader.requested], timeout: 5)
        let urlAsset = try XCTUnwrap(player).asset.urlAsset
        let loadEnded = expectation(description: "Load ended")
        Task {
            _ = try? await urlAsset.load(.duration)
            loadEnded.fulfill()
        }

        player = nil

        await fulfillment(of: [loadEnded], timeout: 5)
    }

    func test_secondsOfLoadedDuration_reportsAnIndefiniteDurationAsZero() {
        XCTAssertEqual(Player.seconds(ofLoadedDuration: .indefinite), 0)
    }

    // MARK: Private

    private var audioFiles: SilentAudioFiles!

    /// A remote asset whose data never arrives. Builds it in a helper so the test holds only its players.
    private func makePendingRemoteAsset(loader: PendingResourceLoader) throws -> PlayerAsset {
        let asset = try PlayerAsset(url: XCTUnwrap(URL(string: "pending://reciter/002.mp3")))
        // Before any player exists: a player item starts loading its asset as soon as it's created.
        asset.urlAsset.resourceLoader.setDelegate(loader, queue: .main)
        return asset
    }

    private func waitForDuration(of player: Player) async {
        let loaded = expectation(description: "Duration loaded")
        player.onDurationLoaded = { _ in loaded.fulfill() }
        await fulfillment(of: [loaded], timeout: 5)
    }
}

/// Serves a remote asset whose data never arrives, so its loads stay in flight until cancelled.
private final class PendingResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
    // MARK: Lifecycle

    override init() {
        super.init()
        requested.assertForOverFulfill = false
    }

    // MARK: Internal

    let requested = XCTestExpectation(description: "Resource requested")

    func resourceLoader(
        _ resourceLoader: AVAssetResourceLoader,
        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
    ) -> Bool {
        requested.fulfill()
        return true
    }
}
