//
//  RecitationColorTests.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import UIKit
import XCTest
@testable import NoorUI

final class RecitationColorTests: XCTestCase {
    func test_recitation_isSaffron() {
        XCTAssertEqual(hex(.recitation, .light), "#dc7702")
        XCTAssertEqual(hex(.recitation, .dark), "#ef911d")
    }

    // MARK: Private

    private func hex(_ color: UIColor, _ style: UIUserInterfaceStyle) -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: style)).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        let bytes = [red, green, blue].map { Int(($0 * 255).rounded()) }
        return String(format: "#%02x%02x%02x", bytes[0], bytes[1], bytes[2])
    }
}
