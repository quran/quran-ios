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

    func test_requestSignOut_presentsTheConfirmation_withNothingUnsynced() async {
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))

        await sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
        XCTAssertEqual(sut.unsyncedCount, 0)
        XCTAssertEqual(
            signOutConfirmationMessage(unsyncedCount: sut.unsyncedCount),
            l("setting.quran_account.sign_out.confirmation.message")
        )
    }

    /// The test database never syncs, so a new note stays unsynced and signing out would lose it.
    func test_requestSignOut_warnsAboutUnsyncedItems() async throws {
        try await database.quranDataService.createNote(
            body: "Reflection", startSura: 2, startAyah: 255, endSura: 2, endAyah: 255, timestamp: Date()
        )
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))

        await sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
        XCTAssertEqual(sut.unsyncedCount, 1)
        XCTAssertEqual(signOutConfirmationMessage(unsyncedCount: sut.unsyncedCount), lFormat("sync.sign-out.unsynced", 1))
    }

    func test_signOutMessage_warnsWithoutACount_whenItCouldNotBeRead() {
        XCTAssertEqual(signOutConfirmationMessage(unsyncedCount: nil), l("sync.sign-out.unsynced-unknown"))
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
