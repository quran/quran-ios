#if QURAN_SYNC

import Foundation
import Localization
import MobileSync
import NoorUI
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

    func test_apply_keepsRetryingThroughItsAttempts_untilTheSyncFails() {
        let offline = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let unavailable = MobileSyncRunError(kind: .server, httpStatus: 503, serverCode: nil, message: "unavailable")
        var activity = SyncActivity()

        activity.apply(.status(.retrying(failedAt: date(300), error: offline, nextAttemptAt: date(301))))
        activity.apply(.status(.syncing))
        XCTAssertEqual(activity.state, .retrying(.network))
        XCTAssertTrue(SyncStatusSummary(activity).button.isEnabled)

        activity.apply(.status(.retrying(failedAt: date(302), error: unavailable, nextAttemptAt: date(304))))
        activity.apply(.status(.syncing))
        XCTAssertEqual(activity.state, .retrying(.server))
        XCTAssertEqual(SyncStatusSummary(activity).button, .tryAgain)

        activity.apply(.status(.failed(at: date(310), error: unavailable)))
        XCTAssertEqual(activity.state, .failed(.server))
    }

    func test_apply_keepsRetryingThroughItsAttempts_untilTheSyncSucceeds() {
        let offline = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        var activity = SyncActivity()

        activity.apply(.status(.retrying(failedAt: date(300), error: offline, nextAttemptAt: date(301))))
        activity.apply(.status(.syncing))
        XCTAssertEqual(activity.state, .retrying(.network))

        activity.apply(.status(.succeeded(at: date(305))))
        XCTAssertEqual(activity.state, .synced(at: date(305)))
        activity.apply(.status(.syncing))
        XCTAssertEqual(activity.state, .syncing)
    }

    func test_state_isRetrying_whileAFailedAttemptWaitsToRetry() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let activity = SyncActivity(
            status: .retrying(failedAt: date(300), error: error, nextAttemptAt: date(310)),
            runs: [makeRun(.succeeded, endedAt: 100)]
        )

        XCTAssertEqual(activity.state, .retrying(.network))
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

    func test_summary_saysSyncedJustNow_withinAMinute() {
        let summary = SyncStatusSummary(SyncActivity(status: .succeeded(at: Date().addingTimeInterval(-5))))

        XCTAssertEqual(summary.title, lFormat("sync.status.synced", l("sync.status.just-now")))
    }

    func test_syncedTimeAgo_saysJustNow_forTheLastMinuteAndASlightlyAheadClock() {
        XCTAssertEqual(Date().addingTimeInterval(-59).syncedTimeAgo(), l("sync.status.just-now"))
        XCTAssertEqual(Date().addingTimeInterval(30).syncedTimeAgo(), l("sync.status.just-now"))
    }

    func test_syncedTimeAgo_saysHowLongAgo_afterAMinute() {
        let twoHoursAgo = Date().addingTimeInterval(-2 * 60 * 60)

        XCTAssertEqual(twoHoursAgo.syncedTimeAgo(), twoHoursAgo.timeAgo())
        XCTAssertNotEqual(twoHoursAgo.syncedTimeAgo(), l("sync.status.just-now"))
    }

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

    func test_summary_saysWhatStaysOnTheDevice_withTheFailureReasonAndTryAgain() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.failed, endedAt: 100, error: error)]))

        XCTAssertEqual(summary.icon, .failed)
        XCTAssertEqual(summary.title, l("sync.status.failed"))
        XCTAssertEqual(summary.detail, lFormat("sync.status.failed.kept", l("sync.error.network")))
        XCTAssertEqual(summary.button, .tryAgain)
    }

    func test_summary_saysWhatStaysOnTheDevice_andRetryingSoon_whileRetrying() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let summary = SyncStatusSummary(SyncActivity(status: .retrying(failedAt: date(300), error: error, nextAttemptAt: date(310))))

        XCTAssertEqual(summary.icon, .failed)
        XCTAssertEqual(summary.title, l("sync.status.failed"))
        XCTAssertEqual(summary.detail, lFormat("sync.status.failed.kept", lFormat("sync.status.retrying", l("sync.error.network"))))
        XCTAssertEqual(summary.button, .tryAgain)
        XCTAssertTrue(summary.button.isEnabled)
    }

    func test_summary_showsAnUnknownFailure_whenAFailedRunHasNoError() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.failed, endedAt: 100)]))

        XCTAssertEqual(summary.detail, lFormat("sync.status.failed.kept", l("sync.error.unknown")))
    }

    func test_cardSummary_leadsWithTheHeldCount_andPutsTheTimeInTheDetail() {
        let syncedAt = Date().addingTimeInterval(-120)
        let activity = SyncActivity(
            runs: [makeRun(.succeeded, endedAt: syncedAt.timeIntervalSince1970)],
            heldItems: [heldItem(.note, id: "n1", reason: .tooShort)]
        )

        let summary = SyncStatusSummary(activity, style: .card)

        XCTAssertEqual(summary.tone, .caution)
        XCTAssertEqual(summary.title, lFormat("sync.held.count", 1))
        XCTAssertEqual(summary.detail, lFormat("sync.status.everything-else-synced", nonBreaking(syncedAt.timeAgo())))
    }

    func test_cardSummary_showsSynced_withWhatSyncsAndTheTimeInTheDetail() {
        let syncedAt = Date().addingTimeInterval(-120)
        let activity = SyncActivity(runs: [makeRun(.succeeded, endedAt: syncedAt.timeIntervalSince1970)])

        let summary = SyncStatusSummary(activity, style: .card)

        XCTAssertEqual(summary.icon, .synced)
        XCTAssertEqual(summary.tone, .normal)
        XCTAssertEqual(summary.title, l("sync.status.synced.short"))
        XCTAssertEqual(summary.detail, lFormat("sync.status.synced.card", nonBreaking(syncedAt.timeAgo())))
        XCTAssertFalse(summary.hasHeldItems)
    }

    /// The card's detail is narrow, so the time stays on one line, such as "2 minutes ago".
    func test_cardSummary_keepsTheTimeOnOneLine() {
        let syncedAt = Date().addingTimeInterval(-120)
        let timeAgo = syncedAt.timeAgo()
        let activity = SyncActivity(runs: [makeRun(.succeeded, endedAt: syncedAt.timeIntervalSince1970)])

        let detail = SyncStatusSummary(activity, style: .card).detail

        let time = String(detail.suffix(timeAgo.count))
        XCTAssertTrue(timeAgo.contains(" "))
        XCTAssertFalse(time.contains(" "))
        XCTAssertEqual(time.replacingOccurrences(of: "\u{00A0}", with: " "), timeAgo)
    }

    func test_cardSummary_saysJustNow_forASyncInTheLastMinute() {
        let syncedAt = Date().addingTimeInterval(-5)
        let synced = SyncActivity(runs: [makeRun(.succeeded, endedAt: syncedAt.timeIntervalSince1970)])
        let held = SyncActivity(
            runs: [makeRun(.succeeded, endedAt: syncedAt.timeIntervalSince1970)],
            heldItems: [heldItem(.note, id: "n1", reason: .tooShort)]
        )

        let justNow = l("sync.status.just-now")
        XCTAssertEqual(SyncStatusSummary(synced, style: .card).detail, lFormat("sync.status.synced.card", nonBreaking(justNow)))
        XCTAssertEqual(
            SyncStatusSummary(held, style: .card).detail,
            lFormat("sync.status.everything-else-synced", nonBreaking(justNow))
        )
    }

    /// The card keeps offering to review held items while it syncs or after a failure.
    func test_cardSummary_keepsHeldItems_whileSyncing() {
        let activity = SyncActivity(status: .syncing, heldItems: [heldItem(.note, id: "n1", reason: .tooShort)])

        let summary = SyncStatusSummary(activity, style: .card)

        XCTAssertEqual(summary.icon, .syncing)
        XCTAssertEqual(summary.detail, l("sync.status.items.short"))
        XCTAssertTrue(summary.hasHeldItems)
    }

    func test_cardSummary_keepsHeldItems_afterAFailure() {
        let activity = SyncActivity(
            runs: [makeRun(.failed, endedAt: 100)],
            heldItems: [heldItem(.note, id: "n1", reason: .tooShort)]
        )

        let summary = SyncStatusSummary(activity, style: .card)

        XCTAssertEqual(summary.icon, .failed)
        XCTAssertTrue(summary.hasHeldItems)
    }

    func test_cardSummary_hasNoHeldItems_whenOnlyWaitingItemsAreLeft() {
        let parent = heldItem(.collection, id: "c1", reason: .reservedName)
        let activity = SyncActivity(heldItems: [heldItem(.collectionBookmark, id: "2:255", reason: .waitingOnParent, waitingOn: parent)])

        XCTAssertFalse(SyncStatusSummary(activity, style: .card).hasHeldItems)
    }

    func test_cardSummary_saysWhatSyncs_whileSyncing() {
        let summary = SyncStatusSummary(SyncActivity(status: .syncing), style: .card)

        XCTAssertEqual(summary.title, l("sync.status.syncing"))
        XCTAssertEqual(summary.detail, l("sync.status.items.short"))
    }

    func test_cardSummary_showsTheFailureInRed_withWhatStaysOnTheDevice() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.failed, endedAt: 100)]), style: .card)

        XCTAssertEqual(summary.tone, .failure)
        XCTAssertEqual(summary.title, l("sync.status.failed"))
        XCTAssertEqual(summary.detail, lFormat("sync.status.failed.kept", l("sync.error.unknown")))
    }

    /// A run that only pulled has no error, so the card only says what stays on the device.
    func test_cardSummary_saysSendingIsPaused_whenTheLatestRunOnlyPulled() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.pulledOnly, endedAt: 100)]), style: .card)

        XCTAssertEqual(summary.detail, l("sync.status.failed.kept.paused"))
    }

    func test_cardSummary_showsWhatSyncs_beforeTheFirstSync() {
        let summary = SyncStatusSummary(SyncActivity(), style: .card)

        XCTAssertEqual(summary.title, l("sync.status.never-synced"))
        XCTAssertEqual(summary.detail, l("sync.status.all-items"))
    }

    func test_cardSummary_showsAWaitingRetryInRed_withTryAgain() {
        let error = MobileSyncRunError(kind: .server, httpStatus: 503, serverCode: nil, message: "unavailable")
        let activity = SyncActivity(status: .retrying(failedAt: date(300), error: error, nextAttemptAt: date(310)))

        let summary = SyncStatusSummary(activity, style: .card)

        XCTAssertEqual(summary.tone, .failure)
        XCTAssertEqual(summary.title, l("sync.status.failed"))
        // The card leaves out "Retrying soon" to keep the line short beside the button.
        XCTAssertEqual(summary.detail, lFormat("sync.status.failed.kept", l("sync.error.server")))
        XCTAssertTrue(summary.button.isEnabled)
    }

    func test_screenSummary_listsWhatSyncs_whenSynced() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.succeeded, endedAt: Date().timeIntervalSince1970)]))

        XCTAssertEqual(summary.detail, l("sync.status.all-items"))
    }

    func test_screenSummary_saysWhatSyncs_whileSyncing() {
        let summary = SyncStatusSummary(SyncActivity(status: .syncing))

        XCTAssertEqual(summary.title, l("sync.status.syncing"))
        XCTAssertEqual(summary.detail, l("sync.status.all-items"))
    }

    /// A run that only pulled has no error, so the screen only says what stays on the device.
    func test_screenSummary_saysWhatStaysOnTheDevice_whenTheLatestRunOnlyPulled() {
        let summary = SyncStatusSummary(SyncActivity(runs: [makeRun(.pulledOnly, endedAt: 100)]))

        XCTAssertEqual(summary.title, l("sync.status.failed"))
        XCTAssertEqual(summary.detail, l("sync.status.failed.kept.paused"))
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
        waitingOn: waitingOn.map { MobileSyncHeldItem.Blocker(type: $0.type, id: $0.id, collectionID: $0.collectionID, reason: $0.reason) },
        httpStatus: nil,
        serverCode: nil
    )
}

func date(_ seconds: TimeInterval) -> Date {
    Date(timeIntervalSince1970: seconds)
}

/// The card keeps a time on one line with non-breaking spaces.
private func nonBreaking(_ time: String) -> String {
    time.replacingOccurrences(of: " ", with: "\u{00A0}")
}

#endif
