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
        await sut.requestSignOut()

        sut.reviewUnsyncedItems()

        XCTAssertFalse(sut.scrollsToHeldItems)
        XCTAssertEqual(signOuts, 0)
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    // MARK: Sign-out warning

    func test_signOutWarning_countsItemsThatCannotSync() {
        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 0, held: 2))

        XCTAssertEqual(warning.message, [lFormat("sync.sign-out.held", 2), l("sync.sign-out.unsynced-lost")].joined(separator: "\n"))
        XCTAssertTrue(warning.offersReview)
    }

    func test_signOutWarning_countsPendingAndHeldItemsApart() {
        let warning = SignOutWarning(unsynced: MobileSyncUnsyncedItemCounts(pending: 3, held: 1))

        XCTAssertEqual(
            warning.message,
            [lFormat("sync.sign-out.pending", 3), lFormat("sync.sign-out.held", 1), l("sync.sign-out.unsynced-lost")]
                .joined(separator: "\n")
        )
        XCTAssertTrue(warning.offersReview)
    }

    func test_signOutWarning_warnsWithoutCounts_whenTheyCouldNotBeRead() {
        let warning = SignOutWarning(unsynced: nil)

        XCTAssertEqual(warning.message, l("sync.sign-out.unsynced-unknown"))
        XCTAssertTrue(warning.offersReview)
    }

    /// Plural rules pick the right form for one item and for several.
    func test_signOutWarning_pluralizesTheCounts() {
        XCTAssertEqual(lFormat("sync.sign-out.pending", 1), "1 change is still waiting to sync to Quran.com.")
        XCTAssertEqual(lFormat("sync.sign-out.pending", 2), "2 changes are still waiting to sync to Quran.com.")
        XCTAssertEqual(lFormat("sync.sign-out.held", 1), "1 item can't sync until you fix it.")
        XCTAssertEqual(lFormat("sync.sign-out.held", 2), "2 items can't sync until you fix them.")
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared

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
        AccountSyncViewModel(
            user: nil,
            authenticationClient: client,
            quranDataService: database.quranDataService,
            quranProfileURL: URL(string: "https://quran.com/profile")!,
            syncActivityBuilder: SyncActivityBuilder(container: AppDependenciesStub()),
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
