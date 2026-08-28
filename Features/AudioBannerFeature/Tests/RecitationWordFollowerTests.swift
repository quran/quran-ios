//
//  RecitationWordFollowerTests.swift
//
//
//  Created by Jawad Khokhar on 2026-08-28.
//

import AsyncUtilitiesForTesting
import AudioTimingService
import Foundation
import QuranAudio
import QuranKit
import TestResources
import XCTest
@testable import AudioBannerFeature

@MainActor
final class RecitationWordFollowerTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        emitted = []
        following = []
        try installReciterDatabase(named: "word_segments.db")
        follower = RecitationWordFollower(retriever: ReciterWordSegmentRetriever())
        follower.onWordChanged = { [weak self] word in self?.emitted.append(word) }
        follower.onFollowingChanged = { [weak self] isFollowing in
            self?.following.append(isFollowing)
            self?.loadCompleted?.fulfill()
        }
    }

    override func tearDown() async throws {
        try emptyReciterDirectory()
        try await super.tearDown()
    }

    // MARK: - Following

    func testHighlightsTheWordUnderThePlayhead() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1)])
    }

    func testMovesToTheNextWordAsPlaybackAdvances() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(1.2)
        follower.playbackTime(1.6)
        follower.playbackTime(3.1)

        XCTAssertEqual(emitted, [
            word(ayah: 1, position: 1),
            word(ayah: 1, position: 2),
            word(ayah: 2, position: 1),
        ])
    }

    /// The player reports the time many times per word; repeats must not reach the UI.
    func testReportsAWordOnlyOnceWhileItIsStillBeingRecited() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(1.0)
        follower.playbackTime(1.2)
        follower.playbackTime(1.4999)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1)])
    }

    /// Silence between words holds the highlight rather than flickering it off.
    func testKeepsTheLastWordThroughTheSilenceBetweenWords() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(1.6)
        follower.playbackTime(2.2) // the 2000-2500ms gap
        follower.playbackTime(2.7)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 2), word(ayah: 1, position: 3)])
    }

    func testEmitsNothingBeforeTheFirstWordStarts() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(0.1)

        XCTAssertEqual(emitted, [])
    }

    /// A stalled player reports a non-finite time rather than a position.
    func testEmitsNothingForAnUnusableTime() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(.nan)

        XCTAssertEqual(emitted, [])
    }

    func testSeekingBackwardsHighlightsTheEarlierWordAgain() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.playbackTime(1.6)
        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 2), word(ayah: 1, position: 1)])
    }

    // MARK: - Reciters and suras without timings

    func testGappedReciterHighlightsNothing() async {
        await play(ayah: ayah(1), reciter: reciter(audioType: .gapped))

        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [])
    }

    /// The state of every published reciter database today.
    func testReciterWithoutWordSegmentsHighlightsNothing() async throws {
        try installReciterDatabase(named: "reciter_without_segments.db")

        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [])
    }

    func testSuraWithoutTimingsHighlightsNothing() async {
        await play(ayah: ayah(1, sura: 3), reciter: gapless)

        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [])
    }

    func testNoReciterClearsTheHighlight() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        await play(ayah: ayah(1), reciter: nil)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1), nil])
    }

    // MARK: - Whether there is anything to follow

    func testReportsFollowingWhenTheSuraHasTimings() async {
        await play(ayah: ayah(1), reciter: gapless)

        XCTAssertEqual(following, [true])
        XCTAssertTrue(follower.isFollowing)
    }

    func testReportsNotFollowingWhenTheSuraHasNoTimings() async {
        await play(ayah: ayah(1, sura: 3), reciter: gapless)

        XCTAssertEqual(following, [false])
        XCTAssertFalse(follower.isFollowing)
    }

    func testStoppingReportsNotFollowing() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.stop()

        XCTAssertEqual(following, [true, false])
        XCTAssertFalse(follower.isFollowing)
    }

    /// Backgrounding must not be undone by the next ayah boundary, so suspension is part
    /// of what the caller is told.
    func testSuspendingReportsNotFollowingUntilResumed() async {
        await play(ayah: ayah(1), reciter: gapless)

        follower.suspend()
        follower.resume()

        XCTAssertEqual(following, [true, false, true])
    }

    /// Nothing is loaded until the load returns, so the caller must not observe yet.
    func testIsNotFollowingWhileTheSuraIsStillLoading() {
        follower.playing(ayah: ayah(1), reciter: gapless)

        XCTAssertFalse(follower.isFollowing)
        XCTAssertEqual(following, [])
    }

    // MARK: - Changing sura

    /// The window between an ayah boundary and its timings arriving must highlight
    /// nothing, rather than resolving the playhead against the previous sura.
    func testPlayheadDuringASuraChangeHighlightsNothing() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        // Not awaited: the load for sura 2 is still in flight.
        follower.playing(ayah: ayah(1, sura: 2), reciter: gapless)
        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1)], "no word from the old sura")
    }

    func testHighlightsTheNewSuraOnceItsTimingsArrive() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        await play(ayah: ayah(1, sura: 2), reciter: gapless)
        follower.playbackTime(0.6)

        XCTAssertEqual(emitted, [
            word(ayah: 1, position: 1),
            word(ayah: 1, position: 1, sura: 2),
        ])
    }

    // MARK: - Lifecycle

    func testStoppingClearsTheHighlightAndTheLoadedTimings() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        follower.stop()
        follower.playbackTime(1.6)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1), nil], "no word survives a stop")
    }

    func testStoppingTwiceClearsOnlyOnce() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        follower.stop()
        follower.stop()

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1), nil])
    }

    func testStoppingMidLoadLeavesNothingLoaded() async {
        // Not awaited: the load is still in flight when stop() cancels it.
        follower.playing(ayah: ayah(1), reciter: gapless)
        follower.stop()
        await Task.megaYield()

        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [], "a cancelled load must not install its timings")
        XCTAssertFalse(follower.isFollowing)
    }

    /// A database that fails to open must not disable the sura for the rest of playback.
    func testASuraWhoseLoadFailedIsRetriedAtTheNextAyah() async throws {
        try installUnreadableReciterDatabase()

        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)
        XCTAssertEqual(emitted, [], "nothing to follow while the database is unreadable")

        try installReciterDatabase(named: "word_segments.db")
        await play(ayah: ayah(2), reciter: gapless)
        follower.playbackTime(1.2)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1)], "the next ayah retries")
    }

    /// Suspending keeps the loaded sura, so resuming does not wait for the next ayah.
    func testSuspendingHoldsTheHighlightUntilResumed() async {
        await play(ayah: ayah(1), reciter: gapless)
        follower.playbackTime(1.2)

        follower.suspend()
        follower.playbackTime(1.6)
        XCTAssertEqual(emitted, [word(ayah: 1, position: 1)], "nothing moves while suspended")
        XCTAssertFalse(follower.isFollowing, "the caller can stop observing the playhead")

        follower.resume()
        XCTAssertTrue(follower.isFollowing)
        follower.playbackTime(1.6)

        XCTAssertEqual(emitted, [word(ayah: 1, position: 1), word(ayah: 1, position: 2)])
    }

    // MARK: Private

    private var follower: RecitationWordFollower!
    private var emitted: [Word?] = []
    private var following: [Bool] = []
    private var loadCompleted: XCTestExpectation?

    private let quran = Quran.hafsMadani1405

    /// Unique per test: `DatabaseConnection` pools connections globally by URL, so a path
    /// reused with different contents would serve the previous test's database.
    private let reciterDirectory = "test_reciter_\(UUID().uuidString)"

    private var gapless: Reciter {
        reciter(audioType: .gapless(databaseName: reciterDirectory))
    }

    /// Starts playback the way production does — `playing` does not await its own load —
    /// then waits for that load to report in, so no assertion races real file I/O.
    ///
    /// Requires a call that actually starts a load: repeating the same reciter and sura
    /// returns early without reporting, and would time out here.
    private func play(ayah: AyahNumber, reciter: Reciter?) async {
        let loaded = expectation(description: "word timings loaded")
        loadCompleted = loaded
        follower.playing(ayah: ayah, reciter: reciter)
        await fulfillment(of: [loaded], timeout: 2)
        loadCompleted = nil
    }

    private func installReciterDatabase(named fixture: String) throws {
        let destination = try emptyReciterDirectory()
        try FileManager.default.copyItem(at: TestResources.resourceURL(fixture), to: destination)
    }

    private func installUnreadableReciterDatabase() throws {
        try Data("not a database".utf8).write(to: emptyReciterDirectory())
    }

    /// Clears the whole directory, so SQLite's -wal and -shm siblings cannot outlive a
    /// fixture and corrupt the next one.
    @discardableResult
    private func emptyReciterDirectory() throws -> URL {
        let destination = try XCTUnwrap(gapless.localDatabasePath).url
        let directory = destination.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return destination
    }

    private func reciter(audioType: AudioType) -> Reciter {
        Reciter(
            id: 1,
            nameKey: reciterDirectory,
            directory: reciterDirectory,
            audioURL: URL(string: "https://example.com/audio/")!,
            audioType: audioType,
            hasGaplessAlternative: false,
            category: .arabic
        )
    }

    private func ayah(_ ayah: Int, sura: Int = 1) -> AyahNumber {
        AyahNumber(quran: quran, sura: sura, ayah: ayah)!
    }

    private func word(ayah number: Int, position: Int, sura: Int = 1) -> Word {
        Word(verse: ayah(number, sura: sura), wordNumber: position)
    }
}
