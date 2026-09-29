//
//  AppIconServiceTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Combine
import SystemDependenciesFake
import UIKit
import UIx
import XCTest
@testable import NoorUI

@MainActor
final class AppIconServiceTests: XCTestCase {
    // MARK: Internal

    override func setUp() async throws {
        try await super.setUp()
        iconAccess = AlternateIconAccessFake()
        bundle = SystemBundleFake()
        bundle.info["CFBundleIcons"] = [
            "CFBundleAlternateIcons": ["AppIcon-Blue": ["CFBundleIconName": "AppIcon-Blue"]],
        ]
        service = AppIconService(catalog: catalog, iconAccess: iconAccess, bundle: bundle)
    }

    override func tearDown() async throws {
        AppIconAccent.setCurrent(nil)
        try await super.tearDown()
    }

    func test_isAvailable_whenPlatformSupportsAndBundleDeclaresAlternateIcons() {
        XCTAssertTrue(service.isAvailable)
    }

    func test_isAvailable_falseWithoutPlatformSupport() {
        iconAccess.supportsAlternateIcons = false

        XCTAssertFalse(service.isAvailable)
    }

    func test_isAvailable_falseWithoutDeclaredAlternateIcons() {
        bundle.info["CFBundleIcons"] = ["CFBundlePrimaryIcon": ["CFBundleIconName": "AppIcon"]]

        XCTAssertFalse(service.isAvailable)
    }

    func test_currentOption_followsSystemIcon() {
        XCTAssertEqual(service.currentOption.id, "amber")

        iconAccess.alternateIconName = "AppIcon-Blue"

        XCTAssertEqual(service.currentOption.id, "blue")
    }

    func test_applyAccent_tintsWindowWithCurrentIconAccent() {
        iconAccess.alternateIconName = "AppIcon-Blue"
        let window = UIWindow()

        service.applyAccent(to: window)

        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#56b1fe")
        XCTAssertEqual(window.tintColor.map { hex($0, .light) }, "#025f9d")
    }

    func test_set_changesIconAndAccent() async throws {
        var emittedOptions: [String] = []
        let cancellable = service.currentOptionPublisher.sink { emittedOptions.append($0.id) }

        try await service.set(blue)

        XCTAssertEqual(iconAccess.alternateIconName, "AppIcon-Blue")
        XCTAssertEqual(service.currentOption.id, "blue")
        XCTAssertEqual(emittedOptions, ["amber", "blue"])
        XCTAssertEqual(hex(AppIconAccent.current.color, .light), "#025f9d")
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#56b1fe")
        XCTAssertEqual(hex(.onAccent, .dark), "#00163d")
        cancellable.cancel()
    }

    func test_set_primaryIconClearsAlternateIconNameAndAppliesItsAccent() async throws {
        iconAccess.alternateIconName = "AppIcon-Blue"
        service.applyAccent(to: UIWindow())
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#56b1fe")

        try await service.set(amber)

        XCTAssertNil(iconAccess.alternateIconName)
        XCTAssertEqual(service.currentOption.id, "amber")
        // Differs from the fallback accent, so this checks that `set` applies the primary accent.
        XCTAssertEqual(hex(AppIconAccent.current.color, .light), "#874c00")
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#f5b454")
        XCTAssertEqual(hex(.onAccent, .dark), "#3a2200")
    }

    func test_set_failureKeepsIconAndAccent() async {
        iconAccess.alternateIconName = "AppIcon-Blue"
        service.applyAccent(to: UIWindow())
        iconAccess.setAlternateIconNameError = URLError(.cancelled)
        var emittedOptions: [String] = []
        let cancellable = service.currentOptionPublisher.sink { emittedOptions.append($0.id) }

        do {
            try await service.set(amber)
            XCTFail("Expected the icon change to fail.")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .cancelled)
        }

        XCTAssertEqual(iconAccess.alternateIconName, "AppIcon-Blue")
        XCTAssertEqual(service.currentOption.id, "blue")
        XCTAssertEqual(emittedOptions, ["blue"])
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#56b1fe")
        cancellable.cancel()
    }

    // MARK: Private

    /// A primary accent unlike the fallback, so tests can tell them apart.
    private let amber = AppIconOption.test(
        id: "amber",
        alternateIconName: nil,
        accent: AppIconAccent(light: UIColor(rgb: 0x874C00), dark: UIColor(rgb: 0xF5B454), onDark: UIColor(rgb: 0x3A2200))
    )
    private let blue = AppIconOption.test(id: "blue", alternateIconName: "AppIcon-Blue")

    private var iconAccess: AlternateIconAccessFake!
    private var bundle: SystemBundleFake!
    private var service: AppIconService!

    private var catalog: AppIconCatalog {
        AppIconCatalog(sections: [.init(id: "all", title: "All", previewSize: .large, options: [amber, blue])])
    }

    private func hex(_ color: UIColor, _ style: UIUserInterfaceStyle) -> String {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).hexString
    }
}
