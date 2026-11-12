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
#endif
import SystemDependencies
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

    // MARK: Sync reveal show rules

    func test_nonSyncBuild_neverPresentsSyncReveal() async {
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
        let sut = makeSUT(channel: .testFlight, build: "412", launchVersion: .firstLaunch(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
        #if QURAN_SYNC
        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertEqual(store.lastSeenBuild, "412")
        #endif
    }

    func test_testFlight_newBuildOfSeenVersion_presentsAgain() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        #if QURAN_SYNC
        XCTAssertEqual(versions.map(\.version), ["3.1"])
        XCTAssertEqual(versions.map(\.reveal), [.sync])
        #else
        XCTAssertEqual(versions.map(\.version), [])
        #endif
    }

    func test_testFlight_sameBuild_presentsNothing() async {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "413"
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_testFlight_newBuild_doesNotPresentOlderSeenVersionAgain() async {
        // Seen on an earlier build, but the app now runs a newer marketing version without an entry.
        store.lastSeenVersion = "3.0.1"
        store.lastSeenBuild = "300"
        let sut = makeSUT(channel: .testFlight, build: "301", launchVersion: .update(from: "3.0.1", to: "3.0.2"))

        let versions = await sut.versionsToPresent(in: whatsNewUpTo3_0_1)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_appStore_newBuildOfSeenVersion_presentsNothing() async {
        store.lastSeenVersion = "3.1"
        let sut = makeSUT(channel: .appStore, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        XCTAssertEqual(versions.map(\.version), [])
    }

    func test_appStore_userWhoSaw3_0_1_presentsOnlyNewerVersions() async {
        store.lastSeenVersion = "3.0.1"
        let sut = makeSUT(channel: .appStore, build: "500", launchVersion: .update(from: "3.0.2", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)

        #if QURAN_SYNC
        XCTAssertEqual(versions.map(\.version), ["3.1"])
        #else
        XCTAssertEqual(versions.map(\.version), [])
        #endif
    }

    #if QURAN_SYNC
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

    func test_signedIn_skipsOnlySyncReveal() async throws {
        store.lastSeenVersion = "2.6.2"
        let authenticationClient = AuthenticationClientFake()
        authenticationClient.authenticationStateValue = .authenticated
        let presenter = PresenterFake()
        let sut = makeSUT(authenticationClient: authenticationClient, launchVersion: .update(from: "2.6.8", to: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)
        sut.present(versions, from: presenter, onChooseAnotherIcon: nil)
        try presentedAppIconReveal(by: presenter).rootView.onContinue()

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

    // MARK: Sync reveal actions

    func test_syncRevealSignIn_marksSeenAndSignsInAfterDismissal() throws {
        let analytics = AnalyticsLibrarySpy()
        let presenter = PresenterFake()
        var signInPresenters: [UIViewController] = []
        var isRevealPresentedWhenSigningIn: Bool?
        let sut = makeSUT(
            analytics: analytics,
            launchVersion: .update(from: "3.0.2", to: "3.1"),
            signIn: { viewController in
                isRevealPresentedWhenSigningIn = presenter.presentedController != nil
                signInPresenters.append(viewController)
            }
        )
        sut.present([syncVersion], from: presenter, onChooseAnotherIcon: nil)
        let reveal = try presentedSyncReveal(by: presenter)

        reveal.rootView.onSignIn()
        reveal.rootView.onSignIn()
        reveal.rootView.onNotNow()

        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertEqual(signInPresenters.count, 1)
        XCTAssertIdentical(signInPresenters.first, presenter)
        XCTAssertEqual(isRevealPresentedWhenSigningIn, false)
        XCTAssertEqual(presenter.dismissCount, 1)
        XCTAssertEqual(analytics.events, [
            .init(name: "PresentingWhatsNew", value: "3.1"),
            .init(name: "PresentingSyncReveal", value: "3.1"),
            .init(name: "SyncRevealSignIn", value: "3.1"),
        ])
    }

    func test_syncRevealNotNow_marksSeenAndDismissesWithoutSigningIn() throws {
        let analytics = AnalyticsLibrarySpy()
        let presenter = PresenterFake()
        var signInCount = 0
        let sut = makeSUT(
            analytics: analytics,
            launchVersion: .update(from: "3.0.2", to: "3.1"),
            signIn: { _ in signInCount += 1 }
        )
        sut.present([syncVersion], from: presenter, onChooseAnotherIcon: nil)
        let reveal = try presentedSyncReveal(by: presenter)

        reveal.rootView.onNotNow()

        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertNil(presenter.presentedController)
        XCTAssertEqual(signInCount, 0)
        XCTAssertEqual(analytics.events.last, .init(name: "SyncRevealNotNow", value: "3.1"))
    }

    func test_syncRevealOnTestFlight_remembersBuild() async throws {
        store.lastSeenVersion = "3.1"
        store.lastSeenBuild = "412"
        let presenter = PresenterFake()
        let sut = makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))

        let versions = await sut.versionsToPresent(in: syncWhatsNew)
        sut.present(versions, from: presenter, onChooseAnotherIcon: nil)
        try presentedSyncReveal(by: presenter).rootView.onNotNow()

        XCTAssertEqual(store.lastSeenVersion, "3.1")
        XCTAssertEqual(store.lastSeenBuild, "413")
        let nextLaunch = await makeSUT(channel: .testFlight, build: "413", launchVersion: .sameVersion(version: "3.1"))
            .versionsToPresent(in: syncWhatsNew)
        XCTAssertEqual(nextLaunch.map(\.version), [])
    }
    #endif

    // MARK: Private

    private let store = AppWhatsNewVersionStore()

    private let syncVersion = WhatsNewVersion(version: "3.1", items: [], reveal: .sync)

    private let appIconVersion = WhatsNewVersion(version: "3.0.1", items: [], reveal: .appIcon)

    private lazy var whatsNewUpTo3_0_1 = AppWhatsNew(versions: [appIconVersion])

    private lazy var syncWhatsNew = AppWhatsNew(versions: [syncVersion, appIconVersion])

    #if QURAN_SYNC
    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        channel: AppDistributionChannel = .appStore,
        build: String = "1",
        authenticationClient: any AuthenticationClient = AuthenticationClientFake(),
        launchVersion: LaunchVersionUpdate,
        signIn: @escaping @MainActor (UIViewController) -> Void = { _ in }
    ) -> AppWhatsNewController {
        WhatsNewControllerFactory.make(
            analytics: analytics,
            channel: channel,
            build: build,
            authenticationClient: authenticationClient,
            launchVersion: launchVersion,
            signIn: signIn
        )
    }

    private func presentedSyncReveal(by presenter: PresenterFake) throws -> SyncRevealViewController {
        try XCTUnwrap(presenter.presentedController as? SyncRevealViewController)
    }

    private func presentedAppIconReveal(by presenter: PresenterFake) throws -> AppIconRevealViewController {
        try XCTUnwrap(presenter.presentedController as? AppIconRevealViewController)
    }
    #else
    private func makeSUT(
        channel: AppDistributionChannel = .appStore,
        build: String = "1",
        launchVersion: LaunchVersionUpdate
    ) -> AppWhatsNewController {
        WhatsNewControllerFactory.make(channel: channel, build: build, launchVersion: launchVersion)
    }
    #endif
}
