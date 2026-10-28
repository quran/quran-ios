#if QURAN_SYNC

import Foundation
import Localization
import MobileSync
import XCTest
@testable import SettingsFeature

final class SyncActivityTests: XCTestCase {
    // MARK: State

    func test_state_isNeverSynced_withoutRuns() {
        XCTAssertEqual(SyncActivity().state, .neverSynced)
    }

    func test_state_isSyncing_whileSyncing() {
        let activity = SyncActivity(status: .syncing, runs: [makeRun(.succeeded, endedAt: 100)])

        XCTAssertEqual(activity.state, .syncing)
    }

    /// The status resets to idle at launch, so the stored runs say when it last synced.
    func test_state_isSyncedAtTheLatestSucceededRun_afterLaunch() {
        let activity = SyncActivity(status: .idle, runs: [makeRun(.succeeded, endedAt: 200), makeRun(.succeeded, endedAt: 100)])

        XCTAssertEqual(activity.state, .synced(at: date(200)))
    }

    func test_state_isFailed_whenTheLatestRunFailed() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let activity = SyncActivity(runs: [makeRun(.failed, endedAt: 200, error: error), makeRun(.succeeded, endedAt: 100)])

        XCTAssertEqual(activity.state, .failed(error.kind))
    }

    func test_state_isFailed_whenTheStatusFailedAfterTheLatestRun() {
        let error = MobileSyncRunError(kind: .server, httpStatus: 503, serverCode: nil, message: "unavailable")
        let activity = SyncActivity(status: .failed(at: date(300), error: error), runs: [makeRun(.succeeded, endedAt: 100)])

        XCTAssertEqual(activity.state, .failed(error.kind))
    }

    func test_state_isSynced_whenARunSucceededAfterTheFailedStatus() {
        let error = MobileSyncRunError(kind: .server, httpStatus: 503, serverCode: nil, message: "unavailable")
        let activity = SyncActivity(status: .failed(at: date(100), error: error), runs: [makeRun(.succeeded, endedAt: 200)])

        XCTAssertEqual(activity.state, .synced(at: date(200)))
    }

    /// A run that only pulled means pushes are still paused after the earlier failure.
    func test_state_isFailed_whenTheLatestRunOnlyPulled() {
        let error = MobileSyncRunError(kind: .rejected, httpStatus: 400, serverCode: nil, message: "bad")
        let activity = SyncActivity(runs: [makeRun(.pulledOnly, endedAt: 300), makeRun(.failed, endedAt: 200, error: error)])

        XCTAssertEqual(activity.state, .failed(error.kind))
    }

    /// The status can report a success before the history records its run.
    func test_state_isSynced_whenTheStatusSucceededAfterTheLatestRunFailed() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let activity = SyncActivity(status: .succeeded(at: date(300)), runs: [makeRun(.failed, endedAt: 200, error: error)])

        XCTAssertEqual(activity.state, .synced(at: date(300)))
    }

    func test_state_ignoresCancelledRuns() {
        let activity = SyncActivity(runs: [makeRun(.cancelled, endedAt: 300), makeRun(.succeeded, endedAt: 200)])

        XCTAssertEqual(activity.state, .synced(at: date(200)))
    }

    // MARK: Held items

    func test_blockingItems_leaveOutItemsWaitingOnAnotherItem() {
        let collection = heldItem(.collection, id: "c1", reason: .reservedName)
        let verse = heldItem(.collectionBookmark, id: "2:255", reason: .waitingOnParent, waitingOn: collection)

        let activity = SyncActivity(heldItems: [collection, verse])

        XCTAssertEqual(activity.blockingItems, [collection])
    }

    // MARK: Status summary

    func test_summary_showsHeldCount_whenSyncedWithHeldItems() {
        let activity = SyncActivity(
            runs: [makeRun(.succeeded, endedAt: Date().timeIntervalSince1970)],
            heldItems: [heldItem(.note, id: "n1", reason: .tooShort), heldItem(.note, id: "n2", reason: .tooLong)]
        )

        let summary = SyncStatusSummary(activity)

        XCTAssertEqual(summary.icon, .held)
        XCTAssertEqual(summary.detail, lFormat("sync.held.count", 2))
        XCTAssertEqual(summary.button, .syncNow)
    }

    func test_summary_showsTheFailureReasonAndTryAgain() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.failed, endedAt: 100, error: error)]))

        XCTAssertEqual(summary.icon, .failed)
        XCTAssertEqual(summary.title, l("sync.status.failed"))
        XCTAssertEqual(summary.detail, l("sync.error.network"))
        XCTAssertEqual(summary.button, .tryAgain)
    }

    func test_summary_showsAnUnknownFailure_whenAFailedRunHasNoError() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.failed, endedAt: 100)]))

        XCTAssertEqual(summary.detail, l("sync.error.unknown"))
    }

    func test_summary_disablesTheButtonWhileSyncing() {
        let summary = SyncStatusSummary(SyncActivity(status: .syncing))

        XCTAssertEqual(summary.button, .syncing)
        XCTAssertFalse(summary.button.isEnabled)
    }
}

func makeRun(
    _ result: MobileSyncRunResult,
    endedAt: TimeInterval,
    trigger: MobileSyncRunTrigger = .manual,
    attempts: Int = 1,
    pushed: Int = 0,
    pulled: Int = 0,
    held: Int = 0,
    error: MobileSyncRunError? = nil
) -> MobileSyncRun {
    MobileSyncRun(
        startedAt: date(endedAt - 5),
        endedAt: date(endedAt),
        trigger: trigger,
        result: result,
        attempts: attempts,
        pushed: pushed,
        pulled: pulled,
        held: held,
        error: error
    )
}

func heldItem(
    _ type: MobileSyncResourceType,
    id: String,
    collectionID: String? = nil,
    reason: MobileSyncHeldReason,
    waitingOn: MobileSyncHeldItem? = nil
) -> MobileSyncHeldItem {
    MobileSyncHeldItem(
        type: type,
        id: id,
        collectionID: collectionID,
        reason: reason,
        waitingOn: waitingOn,
        httpStatus: nil,
        serverCode: nil
    )
}

func date(_ seconds: TimeInterval) -> Date {
    Date(timeIntervalSince1970: seconds)
}

#endif
