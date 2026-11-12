//
//  AppWhatsNewSyncRevealTests.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import Analytics
import AnalyticsFake
import AppMigrator
#if QURAN_SYNC
import AuthenticationClient
import AuthenticationClientFake
import SystemDependencies
#endif
import UIKit
import XCTest
@testable import WhatsNewFeature

/// The 3.1 sync reveal's show rules, TestFlight builds included, and its actions.
@MainActor
final class AppWhatsNewSyncRevealTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        AppWhatsNewVersionStore.reset()
    }

    override func tearDown() async throws {
        AppWhatsNewVersionStore.reset()
        try await super.tearDown()
    }

    // MARK: Every build

    func test_syncRevealIsLeftOutOfNonSyncBuilds() async {
        store.lastSeenVersion = "0"
        let sut = makeSUT(launchVersion: .update(from: "3.0.2", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        #if QURAN_SYNC
        XCTAssertEqual(versions.map(\.reveal), [.sync, .appIcon])
        #else
        XCTAssertEqual(versions.map(\.version), ["3.0.1"])
        XCTAssertEqual(versions.map(\.reveal), [.appIcon])
        #endif
    }

    func test_freshInstall_skipsSyncReveal() async {
        let sut = makeSUT(launchVersion: .firstLaunch(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
        #if QURAN_SYNC
        XCTAssertEqual(store.lastSeenVersion, "3.1")
        #else
        XCTAssertEqual(store.lastSeenVersion, "3.0.1")
        #endif
    }

    func test_updateFrom3_0_1_presentsSyncRevealOnlyInSyncBuilds() async {
        store.lastSeenVersion = "3.0.1"
        let sut = makeSUT(launchVersion: .update(from: "3.0.2", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        #if QURAN_SYNC
        XCTAssertEqual(versions.map(\.version), ["3.1"])
        #else
        XCTAssertEqual(versions.map(\.version), [])
        #endif
    }

    #if !QURAN_SYNC
    func test_nonSyncBuild_neverRecordsSeenBuild() async throws {
        store.lastSeenVersion = "2.6.2"
        let presenter = PresenterFake()
        let sut = makeSUT(launchVersion: .update(from: "2.6.8", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)
        sut.present(versions, from: presenter, onChooseAnotherIcon: nil)
        try XCTUnwrap(presenter.presentedController as? AppIconRevealViewController).rootView.onContinue()

        XCTAssertEqual(store.lastSeenVersion, "3.0.1")
        XCTAssertNil(store.lastSeenBuild)
    }
    #endif

    #if QURAN_SYNC

    // MARK: TestFlight

    func test_testFlight_newBuildOfSeenVersion_presentsAgain() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), ["3.1"])
        XCTAssertEqual(versions.map(\.reveal), [.sync])
    }

    func test_testFlight_sameBuild_presentsNothing() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "413"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_testFlight_newBuild_matchesVersionIgnoringTrailingZeros() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1.0"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), ["3.1"])
    }

    func test_testFlight_newBuild_doesNotPresentSyncRevealOfOlderVersion() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let sut = makeSUT(channel: .testFlight, build: "500", launchVersion: .update(from: "3.1", to: "3.2"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_testFlight_newBuild_neverPresentsAppIconRevealAgain() async {
        store.lastSeenVersion = "3.0.1"
        store.lastSeenBuild = "300"
        let sut = makeSUT(channel: .testFlight, build: "301", launchVersion: .sameVersion(version: "3.0.1"))

        let versions = await sut.versionsToPresent(in: AppWhatsNew(versions: [appIconVersion]))

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_appStore_newBuildOfSeenVersion_presentsNothing() async {
        store.lastSeenVersion = "3.1"
        let sut = makeSUT(channel: .appStore, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_appStoreThenTestFlight_sameVersion_presentsAgain() async {
        // Seen on the App Store, which records no build.
        store.lastSeenVersion = "3.1"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), ["3.1"])
    }

    func test_testFlight_seeingTheRevealRemembersTheBuild() async throws {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let presenter = PresenterFake()
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)
        sut.present(versions, from: presenter, onChooseAnotherIcon: nil)
        try presentedSyncReveal(by: presenter).rootView.onNotNow()

        XCTAssertEqual(store.lastSeenBuild, "413")
        let nextLaunch = await makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))
            .versionsToPresent(in: syncWhatsNew)
        XCTAssertEqual(nextLaunch.map(\.version), [])
    }

    // MARK: Signed in

    func test_signedIn_skipsSyncRevealAndMarksItSeen() async {
        store.lastSeenVersion = "3.0.1"
        let authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateValue = .authenticated
        let analytics = AnalyticsLibrarySpy()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: authenticationClient,
            launchVersion: .update(from: "3.0.2", to: "3.1")
        )

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertEqual(analytics.events, [.init(name: "SyncRevealSkippedSignedIn", value: "3.1")])
    }

    func test_signedIn_waitsForTheStoredSessionBeforeDeciding() async {
        store.lastSeenVersion = "3.0.1"
        // MobileSync reports signed out while it reads the stored session at launch.
        let authenticationClient = AuthenticationClientFake(restoringSession: true)
        let sut = makeSUT(authenticationClient: authenticationClient, launchVersion: .update(from: "3.0.2", to: "3.1"))

        let decision = Task { await sut.versionsToPresent(in: syncWhatsNew) }
        for _ in 0 ..< 50 {
            await Task.yield()
        }
        // The session is read: signed in, with the profile not known yet.
        authenticationClient.authenticationStateValue = .authenticated
        authenticationClient.loggedInUserValue = nil
        let versions = await decision.value

        XCTAssertEqual(versions.map(\.version), [])
        XCTAssertEqual(store.lastSeenVersion, "3.1")
    }

    func test_signedIn_skipsOnlySyncReveal() async throws {
        store.lastSeenVersion = "2.6.2"
        let authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateValue = .authenticated
        let presenter = PresenterFake()
        let sut = makeSUT(authenticationClient: authenticationClient, launchVersion: .update(from: "2.6.8", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)
        sut.present(versions, from: presenter, onChooseAnotherIcon: nil)
        try XCTUnwrap(presenter.presentedController as? AppIconRevealViewController).rootView.onContinue()

        XCTAssertEqual(versions.map(\.version), ["3.0.1"])
        // The older reveal never moves the seen version back.
        XCTAssertEqual(store.lastSeenVersion, "3.1")
    }

    func test_signedOut_presentsSyncReveal() async {
        store.lastSeenVersion = "3.0.1"
        let sut = makeSUT(launchVersion: .update(from: "3.0.2", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.reveal), [.sync])
        XCTAssertEqual(store.lastSeenVersion, "3.0.1")
    }

    // MARK: Actions

    func test_signIn_marksSeenAndSignsInAfterDismissal() async throws {
        let analytics = AnalyticsLibrarySpy()
        let authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateAfterLogin = .authenticated
        let presenter = PresenterFake()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: authenticationClient,
            launchVersion: .update(from: "3.0.2", to: "3.1")
        )
        sut.present([syncVersion], from: presenter, onChooseAnotherIcon: nil)
        let reveal = try presentedSyncReveal(by: presenter)

        reveal.rootView.onSignIn()
        reveal.rootView.onSignIn()
        reveal.rootView.onNotNow()
        await waitUntil { authenticationClient.authenticationStateValue == .authenticated }

        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertEqual(presenter.dismissCount, 1)
        XCTAssertEqual(authenticationClient.events.filter { $0 == .login }.count, 1)
        XCTAssertEqual(analytics.events, [
            .init(name: "PresentingWhatsNew", value: "3.1"),
            .init(name: "PresentingSyncReveal", value: "3.1"),
            .init(name: "SyncRevealSignIn", value: "3.1"),
            .init(name: "QuranSyncSignIn", value: "whats_new"),
        ])
    }

    func test_notNow_marksSeenAndDismissesWithoutSigningIn() throws {
        let analytics = AnalyticsLibrarySpy()
        let authenticationClient = AuthenticationClientFake()
        let presenter = PresenterFake()
        let sut = makeSUT(
            analytics: analytics,
            authenticationClient: authenticationClient,
            launchVersion: .update(from: "3.0.2", to: "3.1")
        )
        sut.present([syncVersion], from: presenter, onChooseAnotherIcon: nil)

        try presentedSyncReveal(by: presenter).rootView.onNotNow()

        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertNil(presenter.presentedController)
        XCTAssertFalse(authenticationClient.events.contains(.login))
        XCTAssertEqual(analytics.events.last, .init(name: "SyncRevealNotNow", value: "3.1"))
    }

    func test_notNow_presentsOlderFeatureItemsAfterDismissal() throws {
        let presenter = PresenterFake()
        let sut = makeSUT(launchVersion: .update(from: "2.6.0", to: "3.1"))
        sut.present([syncVersion, featuresVersion], from: presenter, onChooseAnotherIcon: nil)

        try presentedSyncReveal(by: presenter).rootView.onNotNow()

        let featureList = try XCTUnwrap(presenter.presentedController as? UINavigationController)
        let features = try XCTUnwrap(featureList.viewControllers.first as? AppWhatsNewViewController)
        XCTAssertEqual(features.rootView.items.map(\.title), ["new.reading_layouts"])
        XCTAssertEqual(store.lastSeenVersion, "3.1")
    }
    #endif

    // MARK: Private

    private let store = AppWhatsNewVersionStore()

    private let syncVersion = WhatsNewVersion(version: "3.1", items: [], reveal: .sync)

    private let appIconVersion = WhatsNewVersion(version: "3.0.1", items: [], reveal: .appIcon)

    private let featuresVersion = WhatsNewVersion(
        version: "2.6.2",
        items: [WhatsNewItem(title: "new.reading_layouts", subtitle: "new.reading_layouts.details", image: "book", tags: nil)],
        reveal: nil
    )

    private lazy var syncWhatsNew = AppWhatsNew(versions: [syncVersion, appIconVersion])

    #if QURAN_SYNC
    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        channel: AppDistributionChannel = .appStore,
        build: String = "1",
        authenticationClient: any AuthenticationClient = AuthenticationClientFake(),
        launchVersion: LaunchVersionUpdate
    ) -> AppWhatsNewController {
        WhatsNewControllerFactory.make(
            analytics: analytics,
            channel: channel,
            build: build,
            authenticationClient: authenticationClient,
            launchVersion: launchVersion
        )
    }

    private func presentedSyncReveal(by presenter: PresenterFake) throws -> SyncRevealViewController {
        try XCTUnwrap(presenter.presentedController as? SyncRevealViewController)
    }

    /// Lets the sign-in task run until `condition` holds.
    private func waitUntil(_ condition: () -> Bool) async {
        for _ in 0 ..< 100 where !condition() {
            await Task.yield()
        }
    }
    #else
    private func makeSUT(launchVersion: LaunchVersionUpdate) -> AppWhatsNewController {
        WhatsNewControllerFactory.make(launchVersion: launchVersion)
    }
    #endif
}
