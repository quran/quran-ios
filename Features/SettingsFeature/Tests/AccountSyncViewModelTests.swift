#if QURAN_SYNC

import AuthenticationClient
import AuthenticationClientFake
import Combine
import Foundation
import Localization
import MobileSync
import MobileSyncTestSupport
import UIKit
import XCTest
@testable import SettingsFeature

@MainActor
final class AccountSyncViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    func test_start_showsTheUpdatedUser() async {
        let client = signedInClient(email: "old@example.com")
        let sut = makeSUT(client: client)
        let observation = Task { await sut.start() }

        client.loggedInUserValue = MobileSyncUser(id: "1", name: "Aisha Rahman", email: "new@example.com")

        await waitUntil(sut.$user) { $0?.email == "new@example.com" }
        observation.cancel()
    }

    /// The test database never syncs, so the screen shows a signed-in account that hasn't synced yet.
    func test_start_showsNoSyncsAndNothingHeld_beforeTheFirstSync() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, timestamp: Date()
        )
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))
        // The status, the runs and the held items each arrive once from MobileSync.
        let activityArrived = expectation(description: "The sync activity arrived")
        activityArrived.expectedFulfillmentCount = 3
        activityArrived.assertForOverFulfill = false
        let recording = sut.$activity.dropFirst().sink { _ in activityArrived.fulfill() }
        let observation = Task { await sut.start() }

        await fulfillment(of: [activityArrived], timeout: 5)
        await waitUntil(sut.$lookup) { !$0.notesByID.isEmpty }
        recording.cancel()

        XCTAssertEqual(sut.status.title, l("sync.status.never-synced"))
        XCTAssertTrue(sut.recentRuns.isEmpty)
        XCTAssertTrue(sut.heldRows.isEmpty)
        observation.cancel()
    }

    func test_signOut_returnsToSettings() async {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)
        var signOuts = 0
        let sut = makeSUT(
            client: signedInClient(email: "user@example.com"),
            signOut: { signOuts += 1 },
            navigationController: navigationController
        )

        await sut.signOutOfQuranCom()

        XCTAssertEqual(signOuts, 1)
        XCTAssertEqual(navigationController.viewControllers.count, 1)
        XCTAssertNil(sut.error)
    }

    func test_signOut_showsTheErrorAndStays_whenItFails() async {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)
        let sut = makeSUT(
            client: signedInClient(email: "user@example.com"),
            signOut: { throw AuthenticationClientError.cancelled },
            navigationController: navigationController
        )

        await sut.signOutOfQuranCom()

        XCTAssertNotNil(sut.error)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    func test_showActivity_opensSyncActivity() {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        let sut = makeSUT(client: signedInClient(email: "user@example.com"), navigationController: navigationController)

        sut.showActivity()

        XCTAssertEqual(navigationController.viewControllers.count, 2)
        XCTAssertEqual(navigationController.topViewController?.title, l("sync.activity.title"))
    }

    func test_requestSignOut_saysEverythingSynced_withNothingUnsynced() async {
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))

        await sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
        XCTAssertEqual(sut.unsyncedItems, MobileSyncUnsyncedItemCounts(pending: 0, held: 0))
        XCTAssertEqual(sut.signOutWarning.message, l("setting.quran_account.sign_out.confirmation.message"))
        XCTAssertFalse(sut.signOutWarning.offersReview)
    }

    /// The test database never syncs, so a new note stays pending and signing out would lose it.
    func test_requestSignOut_warnsAboutPendingChanges() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, timestamp: Date()
        )
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))

        await sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
        XCTAssertEqual(sut.unsyncedItems, MobileSyncUnsyncedItemCounts(pending: 1, held: 0))
        XCTAssertEqual(
            sut.signOutWarning.message,
            [lFormat("sync.sign-out.pending", 1), l("sync.sign-out.unsynced-lost")].joined(separator: "\n")
        )
        XCTAssertTrue(sut.signOutWarning.offersReview)
    }

    /// A double tap cancels the first read, which then ends without counts; it keeps the counts already read.
    func test_requestSignOut_keepsTheCounts_whenItsTaskIsCancelled() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, timestamp: Date()
        )
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))
        await sut.requestSignOut()
        sut.isSignOutConfirmationPresented = false

        let cancelled = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            await sut.requestSignOut()
        }
        await cancelled.value

        XCTAssertEqual(sut.unsyncedItems, MobileSyncUnsyncedItemCounts(pending: 1, held: 0))
        XCTAssertFalse(sut.isSignOutConfirmationPresented)
    }

    func test_reviewUnsyncedItems_staysWithoutScrolling_whenNothingIsHeld() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, timestamp: Date()
        )
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.pushViewController(UIViewController(), animated: false)
        var signOuts = 0
        let sut = makeSUT(
            client: signedInClient(email: "user@example.com"),
            signOut: { signOuts += 1 },
            navigationController: navigationController
        )
        // The status, the runs and the held items each arrive once from MobileSync.
        let activityArrived = expectation(description: "The sync activity arrived")
        activityArrived.expectedFulfillmentCount = 3
        activityArrived.assertForOverFulfill = false
        let recording = sut.$activity.dropFirst().sink { _ in activityArrived.fulfill() }
        let observation = Task { await sut.start() }
        await fulfillment(of: [activityArrived], timeout: 5)
        recording.cancel()
        await sut.requestSignOut()

        sut.reviewUnsyncedItems()

        XCTAssertFalse(sut.scrollsToHeldItems)
        XCTAssertEqual(signOuts, 0)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
        observation.cancel()
    }

    // MARK: Sign-out warning

    /// MobileSync counts a held collection's verses as held too; the user fixes only the collection, as the Not
    /// syncing list shows.
    func test_signOutWarning_countsWhatToFix_andTheItemsWaitingOnIt() {
        let collection = heldItem(.collection, id: "c1", reason: .reservedName)
        let verses = ["2:255", "18:10", "36:1", "67:1"].map {
            heldItem(.collectionBookmark, id: $0, collectionID: "c1", reason: .waitingOnParent, waitingOn: collection)
        }
        let activity = SyncActivity(heldItems: [collection] + verses)

        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 0, held: 5), activity: activity)

        XCTAssertEqual(
            warning.message,
            [lFormat("sync.sign-out.held-waiting", 1, 4), l("sync.sign-out.unsynced-lost")].joined(separator: "\n")
        )
        XCTAssertTrue(warning.offersReview)
        XCTAssertTrue(warning.showsHeldItems)
    }

    func test_signOutWarning_countsItemsThatCannotSync() {
        let activity = SyncActivity(heldItems: [heldItem(.note, id: "n1", reason: .tooShort), heldItem(.note, id: "n2", reason: .tooLong)])

        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 0, held: 2), activity: activity)

        XCTAssertEqual(warning.message, [lFormat("sync.sign-out.held", 2), l("sync.sign-out.unsynced-lost")].joined(separator: "\n"))
        XCTAssertTrue(warning.showsHeldItems)
    }

    func test_signOutWarning_countsPendingAndHeldItemsApart() {
        let activity = SyncActivity(heldItems: [heldItem(.note, id: "n1", reason: .tooShort)])

        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 3, held: 1), activity: activity)

        XCTAssertEqual(
            warning.message,
            [lFormat("sync.sign-out.pending", 3), lFormat("sync.sign-out.held", 1), l("sync.sign-out.unsynced-lost")]
                .joined(separator: "\n")
        )
        XCTAssertTrue(warning.offersReview)
    }

    func test_signOutWarning_countsEveryHeldItem_beforeTheHeldListArrives() {
        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 0, held: 3), activity: SyncActivity())

        XCTAssertEqual(warning.message, [lFormat("sync.sign-out.held", 3), l("sync.sign-out.unsynced-lost")].joined(separator: "\n"))
        XCTAssertFalse(warning.showsHeldItems)
    }

    func test_signOutWarning_warnsWithoutCounts_whenTheyCouldNotBeRead() {
        let warning = SignOutWarning(unsynced: nil, activity: SyncActivity())

        XCTAssertEqual(warning.message, l("sync.sign-out.unsynced-unknown"))
        XCTAssertTrue(warning.offersReview)
    }

    /// Plural rules pick the right form for one item and for several, whatever the simulator's language.
    func test_signOutWarning_pluralizesTheCounts() {
        XCTAssertEqual(english("sync.sign-out.pending", 1), "1 change is still waiting to sync to Quran.com.")
        XCTAssertEqual(english("sync.sign-out.pending", 2), "2 changes are still waiting to sync to Quran.com.")
        XCTAssertEqual(english("sync.sign-out.held", 1), "1 item can't sync until you fix it.")
        XCTAssertEqual(english("sync.sign-out.held", 2), "2 items can't sync until you fix them.")
        XCTAssertEqual(
            english("sync.sign-out.held-waiting", 1, 4),
            "1 item can't sync until you fix it, and 4 more can't sync until then."
        )
        XCTAssertEqual(
            english("sync.sign-out.held-waiting", 2, 1),
            "2 items can't sync until you fix them, and 1 more can't sync until then."
        )
    }

    /// Arabic has six plural forms, and its forms for one and two leave out the number.
    func test_signOutWarning_pluralizesTheCountsInArabic() {
        XCTAssertEqual(arabic("sync.sign-out.held-waiting", 1, 2), "عنصر واحد لا يمكن مزامنته حتى تصلحه، وعنصران آخران لا يمكن مزامنتهما حتى ذلك الحين.")
        XCTAssertEqual(arabic("sync.sign-out.held-waiting", 3, 11), "3 عناصر لا يمكن مزامنتها حتى تصلحها، و11 عنصرًا آخر لا يمكن مزامنته حتى ذلك الحين.")
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared

    private func english(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: l(key, language: .english), locale: Locale(identifier: "en"), arguments: arguments)
    }

    private func arabic(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: l(key, language: .arabic), locale: Locale(identifier: "ar"), arguments: arguments)
    }

    private func signedInClient(email: String) -> AuthenticationClientFake {
        let client = AuthenticationClientFake()
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = MobileSyncUser(id: "1", email: email)
        return client
    }

    private func makeSUT(
        client: AuthenticationClientFake,
        signOut: @escaping @MainActor () async throws -> Void = {},
        navigationController: UINavigationController? = nil
    ) -> AccountSyncViewModel {
        let container = AppDependenciesStub()
        return AccountSyncViewModel(
            user: nil,
            authenticationClient: client,
            quranDataService: database.quranDataService,
            quranProfileURL: URL(string: "https://quran.com/profile")!,
            syncActivityBuilder: SyncActivityBuilder(container: container),
            editor: SyncActivityBuilder(container: container).heldItemEditor(navigationController: navigationController),
            signOut: signOut,
            navigationController: navigationController
        )
    }

    private func waitUntil<Value>(
        _ publisher: Published<Value>.Publisher,
        satisfies predicate: @escaping (Value) -> Bool
    ) async {
        let satisfied = expectation(description: "Published value satisfies the predicate")
        let observation = publisher.first(where: predicate).sink { _ in satisfied.fulfill() }
        await fulfillment(of: [satisfied], timeout: 5)
        observation.cancel()
    }
}

#endif
