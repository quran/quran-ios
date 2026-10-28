#if QURAN_SYNC

import Foundation
import Localization
import MobileSync
import QuranKit
import QuranLocalization
import XCTest
@testable import SettingsFeature

final class SyncActivityRowsTests: XCTestCase {
    // MARK: Held items

    func test_heldNote_isTitledByItsVersesWithTheReason() throws {
        let lookup = HeldItemLookup(notes: [note(id: "n1", sura: 2, ayah: 255)])

        let row = try XCTUnwrap(HeldItemRow.rows(for: [heldItem(.note, id: "n1", reason: .tooShort)], lookup: lookup).first)

        let ayah = try XCTUnwrap(AyahNumber(quran: .hafsMadani1405, sura: 2, ayah: 255))
        XCTAssertEqual(row.kind, .note)
        XCTAssertEqual(row.title.accessibilityText, lFormat("sync.held.note", ayah.localizedName))
        XCTAssertEqual(row.reason, l("sync.held.reason.too-short"))
        XCTAssertNil(row.waiting)
    }

    func test_heldCollection_countsTheVersesWaitingOnIt() {
        let collection = heldItem(.collection, id: "c1", reason: .rejectedByServer)
        let items = [
            collection,
            heldItem(.collectionBookmark, id: "2:255", collectionID: "c1", reason: .waitingOnParent, waitingOn: collection),
            heldItem(.collectionBookmark, id: "18:10", collectionID: "c1", reason: .waitingOnParent, waitingOn: collection),
        ]
        let lookup = HeldItemLookup(collections: [
            MobileSyncCollection(id: "c1", name: "Morning adhkar", lastUpdated: date(1), isDefault: false, isSystem: false, isReadOnly: false),
        ])

        let rows = HeldItemRow.rows(for: items, lookup: lookup)

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows[0].title.accessibilityText, lFormat("sync.held.collection", "Morning adhkar"))
        XCTAssertEqual(rows[0].reason, l("sync.held.reason.not-accepted.collection"))
        XCTAssertEqual(rows[0].waiting, lFormat("sync.held.waiting.verses", 2))
    }

    func test_heldDefaultCollection_usesTheFavoritesName() throws {
        let lookup = HeldItemLookup(collections: [
            MobileSyncCollection(id: "fav", name: "Favorites", lastUpdated: date(1), isDefault: true, isSystem: false, isReadOnly: false),
        ])

        let row = try XCTUnwrap(HeldItemRow.rows(for: [heldItem(.collection, id: "fav", reason: .notYetLinked)], lookup: lookup).first)

        XCTAssertEqual(row.title.accessibilityText, lFormat("sync.held.collection", l("bookmarks.collections.favorites")))
        XCTAssertEqual(row.reason, l("sync.held.reason.not-linked"))
    }

    func test_heldReadingBookmark_withoutAName_usesItsColor() throws {
        let lookup = HeldItemLookup(readingBookmarks: [
            MobileSyncReadingBookmark(id: "rb", slot: .orange, placement: .unplaced, name: nil, lastUpdated: date(1)),
        ])

        let row = try XCTUnwrap(HeldItemRow.rows(for: [heldItem(.readingBookmark, id: "rb", reason: .tooLong)], lookup: lookup).first)

        XCTAssertEqual(row.kind, .bookmark)
        XCTAssertEqual(row.title.accessibilityText, lFormat("sync.held.reading-bookmark", l("highlight.color.orange")))
    }

    /// A note on this device whose verses don't exist isn't deleted: it shows the verse numbers it has.
    func test_heldNoteWithInvalidVerses_isTitledByItsNumbers() throws {
        let lookup = HeldItemLookup(notes: [note(id: "n1", sura: 2, ayah: 300)])

        let row = try XCTUnwrap(HeldItemRow.rows(for: [heldItem(.note, id: "n1", reason: .invalidRange)], lookup: lookup).first)

        XCTAssertEqual(row.title.accessibilityText, lFormat("sync.held.note", "2:300"))
        XCTAssertEqual(row.reason, l("sync.held.reason.invalid-verses"))
    }

    func test_heldBookmarkOnAMissingVerse_isTitledByItsNumbers() throws {
        let item = heldItem(.collectionBookmark, id: "2:300", collectionID: "c1", reason: .invalidVerse)

        let row = try XCTUnwrap(HeldItemRow.rows(for: [item], lookup: HeldItemLookup()).first)

        XCTAssertEqual(row.title.accessibilityText, lFormat("sync.held.bookmark", "2:300"))
        XCTAssertEqual(row.reason, l("sync.held.reason.invalid-verses"))
    }

    /// An item held while being deleted is no longer in the other models.
    func test_heldDeletedNote_isTitledAsDeleted() throws {
        let row = try XCTUnwrap(HeldItemRow.rows(for: [heldItem(.note, id: "gone", reason: .rejectedByServer)], lookup: HeldItemLookup()).first)

        XCTAssertEqual(row.title.accessibilityText, l("sync.held.deleted-note"))
        XCTAssertEqual(row.reason, l("sync.held.reason.not-accepted.note"))
    }

    // MARK: Runs

    func test_runDetail_listsWhatASucceededRunDid() {
        let row = SyncRunRow(makeRun(.succeeded, endedAt: 100, pushed: 3, pulled: 1))

        XCTAssertEqual(row.outcome, .succeeded)
        XCTAssertEqual(row.detail, [lFormat("sync.run.sent", "3"), lFormat("sync.run.received", "1")].joined(separator: l("sync.separator")))
    }

    func test_runDetail_saysUpToDate_whenNothingChanged() {
        XCTAssertEqual(SyncRunRow(makeRun(.succeeded, endedAt: 100)).detail, l("sync.run.up-to-date"))
    }

    func test_runDetail_showsTheFailureAndAttempts() {
        let error = MobileSyncRunError(kind: .network, httpStatus: nil, serverCode: nil, message: "offline")
        let row = SyncRunRow(makeRun(.failed, endedAt: 100, attempts: 6, error: error))

        XCTAssertEqual(row.outcome, .failed)
        XCTAssertEqual(row.detail, [l("sync.error.network"), lFormat("sync.run.attempts", 6)].joined(separator: l("sync.separator")))
    }

    func test_runDetail_saysSendingPaused_whenItOnlyPulled() {
        let row = SyncRunRow(makeRun(.pulledOnly, endedAt: 100, pulled: 4))

        XCTAssertEqual(row.outcome, .partial)
        XCTAssertEqual(row.detail, [lFormat("sync.run.received", "4"), l("sync.run.sending-paused")].joined(separator: l("sync.separator")))
    }

    func test_runTitle_showsWhenAndWhy() {
        let formatter = SyncRunRow.dateFormatter
        let row = SyncRunRow(makeRun(.succeeded, endedAt: 100, trigger: .appStart))

        XCTAssertEqual(row.title, lFormat("sync.run.title", formatter.string(from: date(100)), l("sync.run.trigger.app-start")))
    }

    // MARK: Profile

    func test_profile_usesTheNameForInitials() {
        let profile = AccountProfile(MobileSyncUser(id: "1", name: "Aisha Rahman", email: "aisha@example.com"))

        XCTAssertEqual(profile.name, "Aisha Rahman")
        XCTAssertEqual(profile.email, "aisha@example.com")
        XCTAssertEqual(profile.initials, "AR")
    }

    func test_profile_joinsFirstAndLastName_withoutAFullName() {
        let profile = AccountProfile(MobileSyncUser(id: "1", firstName: "Aisha", lastName: "Rahman"))

        XCTAssertEqual(profile.name, "Aisha Rahman")
        XCTAssertEqual(profile.initials, "AR")
    }

    func test_profile_usesTheEmailForInitials_withoutAName() {
        let profile = AccountProfile(MobileSyncUser(id: "1", email: "aisha@example.com"))

        XCTAssertNil(profile.name)
        XCTAssertEqual(profile.initials, "A")
    }

    // MARK: Private

    private func note(id: String, sura: Int, ayah: Int) -> MobileSyncNote {
        MobileSyncNote(
            id: id,
            body: "Reflection",
            ranges: [MobileSyncNoteRange(startSura: sura, startAyah: ayah, endSura: sura, endAyah: ayah)],
            lastUpdated: date(1)
        )
    }
}

#endif
