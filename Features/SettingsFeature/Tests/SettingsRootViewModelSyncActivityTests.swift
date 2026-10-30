#if QURAN_SYNC

import AnalyticsFake
import AppDependencies
import AppDependenciesFake
import AppIconFeature
import AudioDownloadsFeature
import AuthenticationClient
import AuthenticationClientFake
import Combine
import Foundation
import MobileSync
import MobileSyncTestSupport
import ReadingSelectorFeature
import SettingsService
import TranslationsFeature
import UIKit
import XCTest
@testable import SettingsFeature

/// The Settings account card's sync activity.
@MainActor
final class SettingsRootViewModelSyncActivityTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        try await database.reset()
    }

    override func tearDown() async throws {
        try await database.reset()
        try await super.tearDown()
    }

    /// The test database never syncs, so the card shows an account that hasn't synced yet.
    func test_observeSyncActivity_followsMobileSync() async {
        let sut = makeSUT(authenticationClient: AuthenticationClientFake())
        let activityArrived = expectation(description: "The sync activity arrived")
        activityArrived.expectedFulfillmentCount = 3
        activityArrived.assertForOverFulfill = false
        let recording = sut.$syncActivity.dropFirst().sink { _ in activityArrived.fulfill() }
        let observation = Task { await sut.observeSyncActivity() }

        await fulfillment(of: [activityArrived], timeout: 5)

        XCTAssertEqual(sut.syncActivity.state, .neverSynced)
        XCTAssertEqual(sut.syncActivity.runs, [])
        XCTAssertEqual(sut.syncActivity.heldItems, [])
        observation.cancel()
        recording.cancel()
    }

    /// MobileSync syncs only while a user is signed in.
    func test_syncNow_doesNothing_whenSignedOut() async throws {
        let sut = makeSUT(authenticationClient: AuthenticationClientFake())

        sut.syncNow()

        let status = try await database.quranDataService.syncStatusSequence().first { _ in true }
        XCTAssertEqual(status, .idle)
    }

    // MARK: Private

    private let database = MobileSyncTestDatabase.shared

    private func makeSUT(authenticationClient: any AuthenticationClient) -> SettingsRootViewModel {
        let container = AppDependenciesFake(authenticationClient: authenticationClient)
        return SettingsRootViewModel(
            analytics: AnalyticsLibrarySpy(),
            reviewService: ReviewService(analytics: AnalyticsLibrarySpy()),
            authenticationClient: authenticationClient,
            quranDataService: database.quranDataService,
            legacyDataImportCoordinator: container.legacyDataImportCoordinator,
            audioPlaybackBuilder: AudioPlaybackBuilder(),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            readingSelectorBuilder: ReadingSelectorBuilder(container: container),
            diagnosticsBuilder: DiagnosticsBuilder(container: container),
            appIconService: container.appIconService(),
            appIconBuilder: AppIconBuilder(container: container),
            accountSyncBuilder: AccountSyncBuilder(container: container),
            navigationController: UINavigationController()
        )
    }
}

#endif
