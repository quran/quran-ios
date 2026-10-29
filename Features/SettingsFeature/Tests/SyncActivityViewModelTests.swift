#if QURAN_SYNC

import Combine
import Foundation
import MobileSync
import MobileSyncTestSupport
import XCTest
@testable import SettingsFeature

@MainActor
final class SyncActivityViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    /// The test database never syncs, so the screen has no runs and nothing held.
    func test_start_followsTheSyncActivity() async {
        let sut = SyncActivityViewModel(quranDataService: database.quranDataService)
        let activityArrived = expectation(description: "The sync activity arrived")
        activityArrived.expectedFulfillmentCount = 3
        activityArrived.assertForOverFulfill = false
        let recording = sut.$activity.dropFirst().sink { _ in activityArrived.fulfill() }
        let observation = Task { await sut.start() }

        await fulfillment(of: [activityArrived], timeout: 5)

        XCTAssertEqual(sut.activity.state, .neverSynced)
        XCTAssertEqual(sut.runs, [])
        XCTAssertTrue(sut.heldRows.isEmpty)
        observation.cancel()
        recording.cancel()
    }

    func test_start_followsTheNotesForHeldItemTitles() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 18, startAyah: 10, endSura: 18, endAyah: 10, timestamp: Date()
        )
        let sut = SyncActivityViewModel(quranDataService: database.quranDataService)
        let notesArrived = expectation(description: "The notes arrived")
        let recording = sut.$lookup.first { !$0.notesByID.isEmpty }.sink { _ in notesArrived.fulfill() }
        let observation = Task { await sut.start() }

        await fulfillment(of: [notesArrived], timeout: 5)

        XCTAssertEqual(sut.lookup.notesByID.values.map(\.body), ["Reflection"])
        observation.cancel()
        recording.cancel()
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared
}

#endif
