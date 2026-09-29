#if QURAN_SYNC

import Analytics
import AppDependencies
import AppIconFeature
import AudioDownloadsFeature
import AuthenticationClient
import AuthenticationClientFake
import BatchDownloader
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

    func test_refreshAuthenticationState_returnsNotAuthenticated_whenClientIsMissing() async {
        let sut = makeSUT(authenticationClient: nil)

        await sut.refreshAuthenticationState()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
    }

    func test_refreshAuthenticationState_returnsRestoredState_whenRestoreSucceeds() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .success(.authenticated)
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        await sut.refreshAuthenticationState()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.events, [.restoreState, .readLoggedInUser])
    }

    func test_refreshAuthenticationState_fallsBackToCurrentState_whenRestoreFails() async {
        let client = AuthenticationClientFake()
        client.restoreStateResult = .failure(.notAuthenticated(underlying: NSError(domain: "test", code: 1)))
        client.authenticationStateValue = .authenticated
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let sut = makeSUT(authenticationClient: client)

        await sut.refreshAuthenticationState()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.events, [.restoreState, .readAuthenticationState, .readLoggedInUser])
    }

    func test_login_updatesAuthenticationStateAndEmail() async {
        let client = AuthenticationClientFake()
        client.authenticationStateValue = .authenticated
        let analytics = AnalyticsRecorder()
        client.loggedInUserValue = makeUser(email: "user@example.com")
        let navigationController = UINavigationController()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: client,
            navigationController: navigationController
        )

        await sut.loginToQuranCom()

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserEmail, "user@example.com")
        XCTAssertEqual(client.events, [.login, .readAuthenticationState, .readLoggedInUser])
        XCTAssertEqual(analytics.events, [.init(name: "QuranSyncSignIn", value: "settings")])
        XCTAssertNil(sut.error)
    }

    func test_login_doesNotSetErrorWhenLoginCompletesWithoutAuthentication() async {
        let client = AuthenticationClientFake()
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: client, navigationController: navigationController)

        await sut.loginToQuranCom()

        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserEmail)
        XCTAssertEqual(client.events, [.login, .readAuthenticationState])
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
        XCTAssertEqual(client.events, [.login])
        XCTAssertNil(sut.error)
    }

    func test_login_setsErrorWhenClientIsMissing() async {
        let navigationController = UINavigationController()
        let sut = makeSUT(authenticationClient: nil, navigationController: navigationController)

        await sut.loginToQuranCom()

        assertClientIsNotAuthenticated(sut.error)
    }

    func test_logout_clearsAuthenticationStateAndEmail() async {
        let client = AuthenticationClientFake()
        let analytics = AnalyticsRecorder()
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
        analytics: AnalyticsLibrary = AnalyticsRecorder(),
        authenticationClient: (any AuthenticationClient)?,
        legacyDataImportCoordinator: LegacyDataImportCoordinator? = nil,
        navigationController: UINavigationController? = nil
    ) -> SettingsRootViewModel {
        let navigationController = navigationController ?? UINavigationController()
        let container = AppDependenciesStub(authenticationClient: authenticationClient ?? UnavailableAuthenticationClient())
        return SettingsRootViewModel(
            analytics: analytics,
            reviewService: ReviewService(analytics: NoopAnalytics()),
            authenticationClient: authenticationClient ?? UnavailableAuthenticationClient(),
            legacyDataImportCoordinator: legacyDataImportCoordinator ?? container.legacyDataImportCoordinator,
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            appIconService: container.appIconService(),
            appIconBuilder: AppIconBuilder(container: container),
            quranProfileURL: container.quranProfileURL,
            navigationController: navigationController
        )
    }

    private let database = MobileSyncTestDatabase.shared

    private func assertClientIsNotAuthenticated(_ error: Error?, file: StaticString = #filePath, line: UInt = #line) {
        guard case .notAuthenticated = error as? AuthenticationClientError else {
            return XCTFail("Expected notAuthenticated, got \(String(describing: error))", file: file, line: line)
        }
    }
}

private struct AnalyticsEvent: Equatable {
    let name: String
    let value: String
}

private final class AnalyticsRecorder: AnalyticsLibrary, @unchecked Sendable {
    private(set) var events: [AnalyticsEvent] = []

    func logEvent(_ name: String, value: String) {
        events.append(.init(name: name, value: value))
    }
}

private func makeUser(email: String?) -> UserInfo {
    UserInfo(
        id: "1",
        firstName: "Test",
        lastName: "User",
        name: "Test User",
        email: email,
        photoUrl: nil
    )
}

#endif
