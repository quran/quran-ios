//
//  AppWhatsNewControllerTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import AnalyticsFake
import AppMigrator
import NoorUI
import UIKit
import XCTest
@testable import WhatsNewFeature

@MainActor
final class AppWhatsNewControllerTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        AppWhatsNewVersionStore.reset()
    }

    override func tearDown() async throws {
        AppWhatsNewVersionStore.reset()
        try await super.tearDown()
    }

    // MARK: Show rules

    func test_firstLaunch_recordsLatestVersionWithoutPresenting() async {
        let sut = makeSUT(launchVersion: .firstLaunch(version: "2.7.0"))

        let versions = await sut.versionsToPresent(in: whatsNew)

        XCTAssertEqual(versions.map(\.version), [])
        XCTAssertEqual(store.lastSeenVersion, "2.7.0")
    }

    func test_updateFromOlderVersion_presentsRevealWithoutMarkingItSeen() async {
        store.lastSeenVersion = "2.6.2"
        let sut = makeSUT(launchVersion: .update(from: "2.6.8", to: "2.7.0"))

        let versions = await sut.versionsToPresent(in: whatsNew)

        XCTAssertEqual(versions.map(\.version), ["2.7.0"])
        XCTAssertEqual(versions.map(\.reveal), [.appIcon])
        XCTAssertEqual(versions.flatMap(\.items).count, 0)
        // The reveal's actions mark the version seen.
        XCTAssertEqual(store.lastSeenVersion, "2.6.2")
    }

    func test_sameVersion_presentsNothing() async {
        store.lastSeenVersion = "2.7.0"
        let sut = makeSUT(launchVersion: .sameVersion(version: "2.7.0"))

        let versions = await sut.versionsToPresent(in: whatsNew)

        XCTAssertEqual(versions.map(\.version), [])
        XCTAssertEqual(store.lastSeenVersion, "2.7.0")
    }

    func test_seenVersionOverride_presentsEveryVersionOnFirstLaunch() async {
        // Same as launching with `-whats-new.seen-version 0`.
        store.lastSeenVersion = "0"
        let sut = makeSUT(launchVersion: .firstLaunch(version: "2.7.0"))

        let versions = await sut.versionsToPresent(in: whatsNew)

        XCTAssertEqual(versions.map(\.version), ["2.7.0", "2.6.2"])
        XCTAssertEqual(versions.map(\.reveal), [.appIcon, nil])
        XCTAssertEqual(store.lastSeenVersion, "0")
    }

    func test_bundledWhatsNew_revealsAppIconForUpdatesFrom2_6() async {
        store.lastSeenVersion = "2.6.2"
        let sut = makeSUT(launchVersion: .update(from: "2.6.8", to: "3.0.1"))

        let versions = await sut.versionsToPresent(in: AppWhatsNewController.bundledWhatsNew())
            .filter { $0.reveal != .sync }

        XCTAssertEqual(versions.map(\.version), ["3.0.1"])
        XCTAssertEqual(versions.map(\.reveal), [.appIcon])
        XCTAssertEqual(versions.flatMap(\.items).count, 0)
    }

    func test_bundledWhatsNew_showsSyncRevealOnlyInSyncBuilds() async {
        store.lastSeenVersion = "3.0.1"
        let sut = makeSUT(launchVersion: .update(from: "3.0.2", to: "3.1"))

        let versions = await sut.versionsToPresent(in: AppWhatsNewController.bundledWhatsNew())

        #if QURAN_SYNC
        XCTAssertEqual(versions.map(\.version), ["3.1"])
        XCTAssertEqual(versions.map(\.reveal), [.sync])
        #else
        XCTAssertEqual(versions.map(\.version), [])
        #endif
    }

    // MARK: Reveal actions

    func test_revealContinue_marksVersionSeenAndDismisses() throws {
        let presenter = PresenterFake()
        let sut = makeSUT(launchVersion: .update(from: "2.6.8", to: "2.7.0"))
        sut.present([revealVersion], from: presenter, onChooseAnotherIcon: {})
        let reveal = try presentedReveal(by: presenter)

        reveal.rootView.onContinue()

        XCTAssertEqual(store.lastSeenVersion, "2.7.0")
        XCTAssertNil(presenter.presentedController)
    }

    func test_revealChooseAnotherIcon_marksVersionSeenAndOpensIconsAfterDismissal() throws {
        let presenter = PresenterFake()
        let sut = makeSUT(launchVersion: .update(from: "2.6.8", to: "2.7.0"))
        var isRevealPresentedWhenChoosing: Bool?
        sut.present([revealVersion], from: presenter, onChooseAnotherIcon: {
            isRevealPresentedWhenChoosing = presenter.presentedController != nil
        })
        let reveal = try presentedReveal(by: presenter)

        try XCTUnwrap(reveal.rootView.onChooseAnotherIcon)()

        XCTAssertEqual(store.lastSeenVersion, "2.7.0")
        XCTAssertEqual(isRevealPresentedWhenChoosing, false)
    }

    func test_revealContinue_presentsOlderFeatureItemsAfterDismissal() throws {
        let presenter = PresenterFake()
        let sut = makeSUT(launchVersion: .update(from: "2.6.0", to: "2.7.0"))
        sut.present(whatsNew.versions, from: presenter, onChooseAnotherIcon: nil)
        let reveal = try presentedReveal(by: presenter)

        reveal.rootView.onContinue()

        let featureList = try XCTUnwrap(presenter.presentedController as? UINavigationController)
        let features = try XCTUnwrap(featureList.viewControllers.first as? AppWhatsNewViewController)
        XCTAssertEqual(features.rootView.items.map(\.title), ["new.reading_layouts"])
        XCTAssertEqual(store.lastSeenVersion, "2.7.0")
    }

    func test_revealActions_completeOnlyOnce() throws {
        let analytics = AnalyticsLibrarySpy()
        let presenter = PresenterFake()
        let sut = makeSUT(analytics: analytics, launchVersion: .update(from: "2.6.8", to: "2.7.0"))
        var chooseAnotherIconCount = 0
        sut.present([revealVersion], from: presenter, onChooseAnotherIcon: { chooseAnotherIconCount += 1 })
        let reveal = try presentedReveal(by: presenter)

        // A double tap on Continue, then a second finger on "Choose Another Icon".
        reveal.rootView.onContinue()
        reveal.rootView.onContinue()
        try XCTUnwrap(reveal.rootView.onChooseAnotherIcon)()

        XCTAssertEqual(analytics.events, [
            .init(name: "PresentingWhatsNew", value: "2.7.0"),
            .init(name: "PresentingAppIconReveal", value: "2.7.0"),
            .init(name: "AppIconRevealContinue", value: "2.7.0"),
        ])
        XCTAssertEqual(presenter.dismissCount, 1)
        XCTAssertEqual(chooseAnotherIconCount, 0)
    }

    func test_revealReplay_logsEachReplayWithoutDismissing() throws {
        let analytics = AnalyticsLibrarySpy()
        let presenter = PresenterFake()
        let sut = makeSUT(analytics: analytics, launchVersion: .update(from: "2.6.8", to: "2.7.0"))
        store.lastSeenVersion = "2.6.2"
        sut.present([revealVersion], from: presenter, onChooseAnotherIcon: nil)
        let reveal = try presentedReveal(by: presenter)

        reveal.rootView.onReplay()
        reveal.rootView.onReplay()

        XCTAssertEqual(analytics.events, [
            .init(name: "PresentingWhatsNew", value: "2.7.0"),
            .init(name: "PresentingAppIconReveal", value: "2.7.0"),
            .init(name: "AppIconRevealReplay", value: "2.7.0"),
            .init(name: "AppIconRevealReplay", value: "2.7.0"),
        ])
        XCTAssertIdentical(presenter.presentedController, reveal)
        XCTAssertEqual(store.lastSeenVersion, "2.6.2")
    }

    // MARK: Private

    private let store = AppWhatsNewVersionStore()

    private let revealVersion = WhatsNewVersion(version: "2.7.0", items: [], reveal: .appIcon)

    private lazy var whatsNew = AppWhatsNew(versions: [
        revealVersion,
        WhatsNewVersion(
            version: "2.6.2",
            items: [WhatsNewItem(title: "new.reading_layouts", subtitle: "new.reading_layouts.details", image: "book", tags: nil)],
            reveal: nil
        ),
    ])

    private func makeSUT(
        analytics: AnalyticsLibrary = AnalyticsLibrarySpy(),
        launchVersion: LaunchVersionUpdate
    ) -> AppWhatsNewController {
        WhatsNewControllerFactory.make(analytics: analytics, launchVersion: launchVersion)
    }

    private func presentedReveal(by presenter: PresenterFake) throws -> AppIconRevealViewController {
        try XCTUnwrap(presenter.presentedController as? AppIconRevealViewController)
    }
}
