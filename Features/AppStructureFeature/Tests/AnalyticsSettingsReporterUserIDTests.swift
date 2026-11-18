//
//  AnalyticsSettingsReporterUserIDTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

#if QURAN_SYNC
import AnalyticsFake
import AuthenticationClientFake
import MobileSync
import UIKit
import XCTest

/// The reporter ties analytics to the signed-in Quran.com account.
extension AnalyticsSettingsReporterTests {
    // MARK: User ID

    func test_signedInUser_setsTheUserID() async {
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1", name: "Aisha", email: "aisha@example.com")
        await start()

        sendNextUser()

        await assertUserIDChanges(["user-1", "next"])
    }

    func test_signedInLaunch_setsTheUserIDOnceTheStoredSessionIsRead() async {
        await startWhileReadingTheStoredSession()

        authenticationClient.authenticationStateValue = .authenticated
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1")
        sendNextUser()

        await assertUserIDChanges(["user-1", "next"])
    }

    func test_signingInAndOut_setsThenClearsTheUserID() async throws {
        authenticationClient.authenticationStateValue = .notAuthenticated
        authenticationClient.authenticationStateAfterLogin = .authenticated
        authenticationClient.loggedInUserAfterLogin = MobileSyncUser(id: "user-1")
        await start()
        await assertUserIDChanges([nil])

        try await authenticationClient.login(on: UIViewController())
        await assertUserIDChanges([nil, "user-1"])
        try await authenticationClient.logout()
        await assertUserIDChanges([nil, "user-1", nil])
        try await signInAsNextUser()

        await assertUserIDChanges([nil, "user-1", nil, "next"])
    }

    func test_profileNotKnownYet_keepsTheUserID() async {
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1")
        await start()
        await assertUserIDChanges(["user-1"])

        authenticationClient.loggedInUserValue = nil
        sendNextUser()

        await assertUserIDChanges(["user-1", "next"])
    }

    /// MobileSync ends a session whose refresh is refused without the client reporting a state change.
    func test_sessionEndedByMobileSync_clearsTheUserID() async throws {
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1")
        await start()
        await assertUserIDChanges(["user-1"])

        authenticationClient.authenticationStateValue = .notAuthenticated
        authenticationClient.loggedInUserValue = nil
        await assertUserIDChanges(["user-1", nil])
        try await signInAsNextUser()

        await assertUserIDChanges(["user-1", nil, "next"])
    }

    func test_refreshedProfile_doesNotSendTheUserIDAgain() async {
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1", name: "Aisha")
        await start()
        await assertUserIDChanges(["user-1"])

        authenticationClient.loggedInUserValue = MobileSyncUser(id: "user-1", name: "Aisha Rahman")
        sendNextUser()

        await assertUserIDChanges(["user-1", "next"])
    }

    func test_signingInAfterTheUserUpdatesFailed_setsTheUserID() async throws {
        authenticationClient.authenticationStateValue = .notAuthenticated
        await start()
        await assertUserIDChanges([nil])

        authenticationClient.failCurrentLoggedInUserUpdates(with: NSError(domain: "test", code: 1))
        try await signInAsNextUser()

        await assertUserIDChanges([nil, "next"])
    }

    // MARK: Private

    /// Ends a test with a known update: updates arrive in order, so any extra user ID lands before it.
    private func sendNextUser() {
        authenticationClient.loggedInUserValue = MobileSyncUser(id: "next")
    }

    private func signInAsNextUser() async throws {
        authenticationClient.authenticationStateAfterLogin = .authenticated
        authenticationClient.loggedInUserAfterLogin = MobileSyncUser(id: "next")
        try await authenticationClient.login(on: UIViewController())
    }

    /// Waits for as many user IDs as `expected` holds, then compares them; end with a known update to catch extras.
    private func assertUserIDChanges(
        _ expected: [String?],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let spy: AnalyticsLibrarySpy = analytics
        let arrived = XCTestExpectation(description: "\(expected.count) user IDs were set")
        let waiting = Task {
            let changes = await spy.userIDChanges(count: expected.count)
            arrived.fulfill()
            return changes
        }
        guard await XCTWaiter().fulfillment(of: [arrived], timeout: 5) == .completed else {
            XCTFail("Expected user IDs \(expected), got \(spy.userIDChanges)", file: file, line: line)
            return
        }
        let changes = await waiting.value
        XCTAssertEqual(changes, expected, file: file, line: line)
    }
}
#endif
