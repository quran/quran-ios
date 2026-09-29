//
//  AppIconListViewModelTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import SystemDependenciesFake
import UIKit
import XCTest
@testable import AppIconFeature
@testable import NoorUI

@MainActor
final class AppIconListViewModelTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        iconAccess = AlternateIconAccessFake()
        bundle = SystemBundleFake()
        bundle.info["CFBundleIcons"] = [
            "CFBundleAlternateIcons": ["AppIcon-Blue": ["CFBundleIconName": "AppIcon-Blue"]],
        ]
        analytics = AnalyticsRecorder()
    }

    override func tearDown() async throws {
        AppIconAccent.setCurrent(nil)
        try await super.tearDown()
    }

    func test_init_selectsCurrentIconAndLogsSource() {
        iconAccess.alternateIconName = "AppIcon-Blue"

        let sut = makeSUT(source: .whatsNew)

        XCTAssertEqual(sut.selectedOption.id, "blue")
        XCTAssertEqual(sut.sections.map(\.id), ["signature", "colors"])
        XCTAssertEqual(analytics.events, [.init(name: "OpeningAppIconsFrom", value: "whatsNew")])
    }

    func test_select_changesIconAndSelection() async {
        let sut = makeSUT()

        await sut.select(blue)

        XCTAssertEqual(iconAccess.alternateIconName, "AppIcon-Blue")
        XCTAssertEqual(sut.selectedOption.id, "blue")
        XCTAssertNil(sut.error)
        XCTAssertEqual(analytics.events, [
            .init(name: "OpeningAppIconsFrom", value: "settings"),
            .init(name: "ChangeAppIconFrom", value: "primary"),
            .init(name: "ChangeAppIconTo", value: "blue"),
            .init(name: "ChangeAppIconResult", value: "success"),
        ])
    }

    func test_select_failureKeepsSelectionAndShowsError() async {
        iconAccess.setAlternateIconNameError = NSError(domain: NSPOSIXErrorDomain, code: 35)
        let sut = makeSUT()

        await sut.select(blue)

        XCTAssertNil(iconAccess.alternateIconName)
        XCTAssertEqual(sut.selectedOption.id, "primary")
        XCTAssertEqual((sut.error as? NSError)?.code, 35)
        XCTAssertEqual(analytics.events.last, .init(name: "ChangeAppIconResult", value: "error:NSPOSIXErrorDomain:35"))
    }

    func test_select_currentIconDoesNothing() async {
        let sut = makeSUT()

        await sut.select(primary)

        XCTAssertNil(iconAccess.alternateIconName)
        XCTAssertEqual(analytics.events, [.init(name: "OpeningAppIconsFrom", value: "settings")])
    }

    // MARK: Private

    private let primary = AppIconOption(
        id: "primary",
        alternateIconName: nil,
        name: "Primary",
        previewImageName: "app-icon-primary",
        accent: AppIconAccent(light: .black, dark: .white, onDark: .black)
    )
    private let blue = AppIconOption(
        id: "blue",
        alternateIconName: "AppIcon-Blue",
        name: "Blue",
        previewImageName: "app-icon-blue",
        accent: AppIconAccent(light: .systemBlue, dark: .systemBlue, onDark: .black)
    )

    private var iconAccess: AlternateIconAccessFake!
    private var bundle: SystemBundleFake!
    private var analytics: AnalyticsRecorder!

    private func makeService() -> AppIconService {
        let catalog = AppIconCatalog(sections: [
            .init(id: "signature", title: "Signature", previewSize: .large, options: [primary]),
            .init(id: "colors", title: "Colors", previewSize: .regular, options: [blue]),
        ])
        return AppIconService(catalog: catalog, iconAccess: iconAccess, bundle: bundle)
    }

    private func makeSUT(source: AppIconListSource = .settings) -> AppIconListViewModel {
        AppIconListViewModel(appIconService: makeService(), analytics: analytics, source: source)
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
