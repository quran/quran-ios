#if QURAN_SYNC

import Analytics
import AnalyticsFake
import AppDependencies
import AppIconFeature
import AudioDownloadsFeature
import AuthenticationClient
import AuthenticationClientFake
import BatchDownloader
import Combine
import CoreDataPersistence
import CoreDataPersistenceTestSupport
import Foundation
import LastPagePersistence
import LegacyDataPersistence
import MobileSync
import MobileSyncTestSupport
import NotePersistence
import PageBookmarkPersistence
import ReadingSelectorFeature
import ReadingService
import SettingsService
import TranslationsFeature
import UIKit
import XCTest
@testable import LegacyDataMigration
@testable import SettingsFeature

@MainActor
final class SettingsRootViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
        LegacyImportPreferences.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        LegacyImportPreferences.reset()
        try await super.tearDown()
    }

    // MARK: Restoring the session

    func test_observeAuthentication_showsSignedOut_whenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)

        // The unavailable client's updates report no user once, then end.
        await sut.observeAuthentication()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
    }

    func test_observeAuthentication_showsSignedOut_whenRestoreReportsSignedOut() async {
        let client = AuthenticationClientFake()
        // Failing the updates first ends the observation right after the restore.
        client.failLoggedInUserUpdates(with: NSError(domain: "test", code: 1))
        let sut = makeSUT(authenticationClient: client)
        sut.isAuthenticated = true
        sut.loggedInUser = makeUser(email: "stale@example.com")

        await sut.observeAuthentication()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
    }

    func test_observeAuthentication_showsUser_afterRestoringSignedInSession() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        let observation = Task { await sut.observeAuthentication() }

        await waitUntil(sut.$loggedInUser) { $0?.email == "user@example.com" }
        XCTAssertTrue(sut.isAuthenticated)
        observation.cancel()
    }

    func test_observeAuthentication_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .failure(.notAuthenticated(underlying: NSError(domain: "test", code: 1)))
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        let observation = Task { await sut.observeAuthentication() }

        await waitUntil(sut.$loggedInUser) { $0?.email == "user@example.com" }
        XCTAssertTrue(sut.isAuthenticated)
        observation.cancel()
    }

    // MARK: Observing the signed-in user

    func test_observeAuthentication_showsUpdatedUser_whileSignedIn() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: "old@example.com")
        let sut = makeSUT(authenticationClient: client)
        let observation = Task { await sut.observeAuthentication() }
        await waitUntil(sut.$loggedInUser) { $0?.email == "old@example.com" }

        // Such as a token refresh that updates the profile.
        client.loggedInUserValue = makeUser(email: "new@example.com")

        await waitUntil(sut.$loggedInUser) { $0?.email == "new@example.com" }
        XCTAssertTrue(sut.isAuthenticated)
        observation.cancel()
    }

    func test_observeAuthentication_keepsShownUser_whenSignedInSessionHasNoUser() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        var emails: [String?] = []
        let recording = sut.$loggedInUser.map { $0?.email }.removeDuplicates().sink { emails.append($0) }
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com")

        // A session stored before MobileSync kept the profile has no user until its next token refresh.
        client.loggedInUserValue = nil
        client.loggedInUserValue = makeUser(email: "refreshed@example.com")

        await waitUntil(sut.$loggedInUser) { $0?.email == "refreshed@example.com" }
        XCTAssertEqual(emails, [nil, "user@example.com", "refreshed@example.com"])
        XCTAssertTrue(sut.isAuthenticated)
        observation.cancel()
        recording.cancel()
    }

    func test_observeAuthentication_showsSignedOut_whenSessionEnds() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com")

        client.authenticationStateValue = .notAuthenticated
        client.loggedInUserValue = nil

        await waitUntil(sut.$isAuthenticated) { !$0 }
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertNil(sut.error)
        observation.cancel()
    }

    func test_observeAuthentication_staysSignedOut_whenSignedOutSessionReportsUser() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let ended = expectation(description: "Observation ended")
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com", ended: ended)
        client.authenticationStateValue = .notAuthenticated
        client.loggedInUserValue = nil
        await waitUntil(sut.$isAuthenticated) { !$0 }

        client.loggedInUserValue = makeUser(email: "stale@example.com")
        // Failing the updates after the user ends the observation once the user is handled.
        client.failLoggedInUserUpdates(with: NSError(domain: "test", code: 1))

        await fulfillment(of: [ended], timeout: 5)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        observation.cancel()
    }

    func test_observeAuthentication_endsWhenCancelled() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let ended = expectation(description: "Observation ended")
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com", ended: ended)

        observation.cancel()

        await fulfillment(of: [ended], timeout: 5)
        client.loggedInUserValue = makeUser(email: "later@example.com")
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
    }

    func test_observeAuthentication_keepsShownUser_whenUpdatesFail() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let ended = expectation(description: "Observation ended")
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com", ended: ended)

        client.failLoggedInUserUpdates(with: NSError(domain: "test", code: 1))

        await fulfillment(of: [ended], timeout: 5)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertNil(sut.error)
        observation.cancel()
    }

    func test_observeAuthentication_endsQuietly_whenUpdatesAreCancelled() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let ended = expectation(description: "Observation ended")
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com", ended: ended)

        // The MobileSync updates throw CancellationError when their task is cancelled.
        client.failLoggedInUserUpdates(with: CancellationError())

        await fulfillment(of: [ended], timeout: 5)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertNil(sut.error)
        observation.cancel()
    }

    func test_observeAuthentication_staysSignedOut_afterSigningOutFromSettings() async {
        let client = AuthenticationClientFake()
        let sut = makeSUT(authenticationClient: client)
        let ended = expectation(description: "Observation ended")
        let observation = await startObservingSignIn(sut, client: client, email: "user@example.com", ended: ended)

        await sut.logoutFromQuranCom()
        // Failing the updates ends the observation once the signed-out update is handled.
        client.failLoggedInUserUpdates(with: NSError(domain: "test", code: 1))

        await fulfillment(of: [ended], timeout: 5)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertNil(sut.error)
        observation.cancel()
    }

    // MARK: Signing in and out

    /// Also covers an observation that already ended after an error, so the card never stays signed out.
    func test_login_updatesAuthenticationState_whenNotObserving() async {
        let client = AuthenticationClientFake()
        client.authenticationStateValue = .authenticated
        let analytics = AnalyticsLibrarySpy()
        let navigationController = UINavigationController()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: client,
            navigationController: navigationController
        )

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(analytics.events, [.init(name: "QuranSyncSignIn", value: "settings")])
        XCTAssertNil(sut.error)
    }

    func test_login_showsSignedInUser_whileObserving() async {
        let client = AuthenticationClientFake()
        client.authenticationStateAfterLogin = .authenticated
        client.loggedInUserAfterLogin = makeUser(email: "user@example.com")
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)
        let observation = await startObservingSignedOut(sut, client: client)

        await sut.loginToQuranCom()

        await waitUntil(sut.$loggedInUser) { $0?.email == "user@example.com" }
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.error)
        observation.cancel()
    }

    func test_login_neverShowsSignedInWithoutUser_whenUserArrivesAfterLogin() async {
        let client = AuthenticationClientFake()
        client.authenticationStateAfterLogin = .authenticated
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)
        let observation = await startObservingSignedOut(sut, client: client)
        var cards: [String] = []
        let signedIn = expectation(description: "Card shows the signed-in user")
        signedIn.assertForOverFulfill = false
        // SwiftUI renders the card once the main actor finishes its current turn, so sample it then.
        let recording = sut.objectWillChange.receive(on: DispatchQueue.main).sink { _ in
            MainActor.assumeIsolated {
                let card = "\(sut.isAuthenticated ? "signed in" : "signed out"), \(sut.currentUserEmail ?? "no email")"
                cards.append(card)
                if card == "signed in, user@example.com" {
                    signedIn.fulfill()
                }
            }
        }

        await sut.loginToQuranCom()
        client.loggedInUserValue = makeUser(email: "user@example.com")

        await fulfillment(of: [signedIn], timeout: 5)
        XCTAssertFalse(cards.contains("signed in, no email"), "\(cards)")
        observation.cancel()
        recording.cancel()
    }

    func test_login_doesNotSetErrorWhenLoginCompletesWithoutAuthentication() async {
        let client = AuthenticationClientFake()
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertNil(sut.error)
    }

    func test_login_doesNotSetErrorWhenUserCancels() async {
        let client = AuthenticationClientFake()
        client.loginResult = .failure(.cancelled)
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertNil(sut.error)
    }

    func test_login_setsErrorWhenClientIsMissing() async {
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: nil, navigationController: navigationController)

        await sut.loginToQuranCom()

        assertClientIsNotAuthenticated(sut.error)
    }

    func test_requestSignOut_presentsConfirmationWithoutSigningOut() {
        let client = AuthenticationClientFake()
        let analytics = AnalyticsLibrarySpy()
        let sut = makeSUT(analytics: analytics, authenticationClient: client)
        sut.isAuthenticated = true
        sut.loggedInUser = makeUser(email: "user@example.com")

        sut.requestSignOut()

        XCTAssertTrue(sut.isSignOutConfirmationPresented)
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.events, [])
        XCTAssertEqual(analytics.events, [])
    }

    func test_logout_clearsAuthenticationStateAndEmail() async {
        let client = AuthenticationClientFake()
        let analytics = AnalyticsLibrarySpy()
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(analytics: analytics, authenticationClient: client)
        sut.isAuthenticated = true
        sut.loggedInUser = makeUser(email: "user@example.com")

        await sut.logoutFromQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertEqual(client.events, [.logout])
        XCTAssertEqual(analytics.events, [.init(name: "QuranSyncSignOut", value: "settings")])
        XCTAssertNil(sut.error)
    }

    func test_logout_disablesLegacyImport() async throws {
        let store = TemporaryCoreDataStore()
        let stack = store.stack()
        try stack.write { context in
            let note = context.newNote("Legacy note", modifiedOn: 1)
            note.addToVerses(context.newVerse(sura: 1, ayah: 1))
        }
        let coordinator = LegacyDataImportCoordinator(
            reader: CoreDataLegacyDataReader(stack: stack),
            quranDataService: database.quranDataService
        )
        let sut = makeSUT(authenticationClient: AuthenticationClientFake(), legacyDataImportCoordinator: coordinator)

        await sut.logoutFromQuranCom()
        try await coordinator.importNow()

        let notes = database.quranDataService.notesSequence().makeAsyncIterator()
        let importedNotes = try await notes.next()
        XCTAssertEqual(importedNotes, [])
    }

    func test_logout_setsErrorWhenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)

        await sut.logoutFromQuranCom()

        assertClientIsNotAuthenticated(sut.error)
    }

    // MARK: Private

    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        authenticationClient: (any AuthenticationClient)?,
        legacyDataImportCoordinator: LegacyDataImportCoordinator? = nil,
        navigationController: UINavigationController? = nil
    ) -> SettingsRootViewModel {
        let navigationController = navigationController ?? UINavigationController()
        let container = AppDependenciesStub(authenticationClient: authenticationClient ?? UnavailableAuthenticationClient())
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: AnalyticsLibrarySpy()),
            authenticationClient: authenticationClient ?? UnavailableAuthenticationClient(),
            legacyDataImportCoordinator: legacyDataImportCoordinator ?? container.legacyDataImportCoordinator,
            audioPlaybackBuilder: AudioPlaybackBuilder(),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            appIconService: container.appIconService(),
            appIconBuilder: AppIconBuilder(container: container),
            accountSyncBuilder: AccountSyncBuilder(container: container),
            quranProfileURL: container.quranProfileURL,
            navigationController: navigationController
        )
    }

    private let database = MobileSyncTestDatabase.shared

    /// Starts observing with a restore that reports signed out and a client that reports signed in with `email`,
    /// so the refresh shows signed out and the user can only arrive through the updates. Returns once it shows.
    private func startObservingSignIn(
        _ sut: SettingsRootViewModel,
        client: AuthenticationClientFake,
        email: String,
        ended: XCTestExpectation? = nil
    ) async -> Task<Void, Never> {
        let observation = Task {
            await sut.observeAuthentication()
            ended?.fulfill()
        }
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: email)
        await waitUntil(sut.$loggedInUser) { $0?.email == email }
        return observation
    }

    /// Starts observing a signed-out session and returns once the observation follows the updates. The restore
    /// reports signed in, such as a session that ends right after it, so only the first update can clear the
    /// stale user.
    private func startObservingSignedOut(
        _ sut: SettingsRootViewModel,
        client: AuthenticationClientFake
    ) async -> Task<Void, Never> {
        client.restoreStateResult = .success(.authenticated)
        sut.loggedInUser = makeUser(email: "stale@example.com")
        let observation = Task { await sut.observeAuthentication() }
        await waitUntil(sut.$loggedInUser) { $0 == nil }
        return observation
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

    private func assertClientIsNotAuthenticated(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard case .notAuthenticated = error as? AuthenticationClientError else {
            return XCTFail("Expected notAuthenticated, got \(String(describing: error))", file: file, line: line)
        }
    }
}

private func makeUser(email: String?) -> MobileSyncUser {
    MobileSyncUser(
        id: "1",
        firstName: "Test",
        lastName: "User",
        name: "Test User",
        email: email
    )
}

#endif
