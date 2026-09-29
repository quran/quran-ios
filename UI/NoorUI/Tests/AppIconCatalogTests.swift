//
//  AppIconCatalogTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import UIKit
import UIx
import XCTest
@testable import NoorUI

final class AppIconCatalogTests: XCTestCase {
    func test_option_primaryIconForNilAlternateIconName() {
        XCTAssertEqual(catalog.option(alternateIconName: nil).id, "navy")
    }

    func test_option_matchesAlternateIconName() {
        XCTAssertEqual(catalog.option(alternateIconName: "AppIcon-Teal").id, "teal")
        XCTAssertEqual(catalog.option(alternateIconName: "AppIcon-Green").id, "green")
    }

    func test_option_unknownAlternateIconNameFallsBackToDefault() {
        XCTAssertEqual(catalog.option(alternateIconName: "AppIcon-Removed").id, "navy")
    }

    func test_defaultOption_isThePrimaryIcon() {
        XCTAssertEqual(catalog.defaultOption.id, "navy")
        XCTAssertTrue(catalog.defaultOption.isPrimary)
    }

    func test_options_keepSectionOrder() {
        XCTAssertEqual(catalog.options.map(\.id), ["navy", "teal", "green"])
        XCTAssertEqual(catalog.sections.map(\.title), ["Signature", "Colors"])
    }

    // MARK: Private

    private let catalog = AppIconCatalog(sections: [
        .init(
            id: "signature",
            title: "Signature",
            previewSize: .large,
            options: [
                .test(id: "navy", alternateIconName: nil),
                .test(id: "teal", alternateIconName: "AppIcon-Teal"),
            ]
        ),
        .init(
            id: "colors",
            title: "Colors",
            previewSize: .regular,
            options: [.test(id: "green", alternateIconName: "AppIcon-Green")]
        ),
    ])
}

extension AppIconOption {
    static func test(id: String, alternateIconName: String?, accent: AppIconAccent = .test) -> AppIconOption {
        AppIconOption(
            id: id,
            alternateIconName: alternateIconName,
            name: id.capitalized,
            previewImageName: "app-icon-\(id)",
            accent: accent
        )
    }
}

extension AppIconAccent {
    static let test = AppIconAccent(
        light: UIColor(rgb: 0x025F9D),
        dark: UIColor(rgb: 0x56B1FE),
        onDark: UIColor(rgb: 0x00163D)
    )
}
