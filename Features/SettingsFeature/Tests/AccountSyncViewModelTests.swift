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
        let observation = Task { await sut.start() }

        await waitUntil(sut.$lookup) { !$0.notesByID.isEmpty }

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

    func test_requestSignOut_presentsTheConfirmation() {
        let sut = makeSUT(client: signedInClient(email: "user@example.com"))

        sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
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
