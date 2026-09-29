//
//  AppIconAccentTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import UIKit
import UIx
import XCTest
@testable import NoorUI

@MainActor
final class AppIconAccentTests: XCTestCase {
    override func tearDown() async throws {
        AppIconAccent.setCurrent(nil)
        try await super.tearDown()
    }

    func test_accent_resolvesPerAppearance() {
        let accent = AppIconAccent(
            light: UIColor(rgb: 0x8D19CB),
            dark: UIColor(rgb: 0xCE90FE),
            onDark: UIColor(rgb: 0x330066)
        )

        XCTAssertEqual(hex(accent.color, .light), "#8d19cb")
        XCTAssertEqual(hex(accent.color, .dark), "#ce90fe")
        XCTAssertEqual(hex(accent.onColor, .light), "#ffffff")
        XCTAssertEqual(hex(accent.onColor, .dark), "#330066")
    }

    func test_currentAccent_followsSetAccent() {
        AppIconAccent.setCurrent(.test)

        XCTAssertEqual(hex(AppIconAccent.current.color, .light), "#025f9d")
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#56b1fe")
        XCTAssertEqual(hex(.onAccent, .light), "#ffffff")
        XCTAssertEqual(hex(.onAccent, .dark), "#00163d")
    }

    func test_currentAccent_usesPackageAccentBeforeAppAppliesItsIcon() {
        XCTAssertEqual(hex(AppIconAccent.current.color, .light), "#874c00")
        XCTAssertEqual(hex(AppIconAccent.current.color, .dark), "#f5b454")
        XCTAssertEqual(hex(.onAccent, .light), "#ffffff")
        XCTAssertEqual(hex(.onAccent, .dark), "#3a2200")
    }

    func test_recitation_staysSaffronWhateverTheAccent() {
        AppIconAccent.setCurrent(.test)

        XCTAssertEqual(hex(.recitation, .light), "#dc7702")
        XCTAssertEqual(hex(.recitation, .dark), "#ef911d")
    }

    // MARK: Private

    private func hex(_ color: UIColor, _ style: UIUserInterfaceStyle) -> String {
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).hexString
    }
}

extension UIColor {
    /// The color as `#rrggbb`, rounding each component to the nearest byte.
    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let bytes = [red, green, blue].map { Int(($0 * 255).rounded()) }
        return String(format: "#%02x%02x%02x", bytes[0], bytes[1], bytes[2])
    }
}
