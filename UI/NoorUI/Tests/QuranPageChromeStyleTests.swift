import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

final class QuranPageChromeStyleTests: XCTestCase {
    func test_onlyMadani1439UsesBlueChrome() {
        for reading in Reading.allReadings {
            XCTAssertEqual(QuranPageChromeStyle(reading: reading), reading == .hafs_1439 ? .blue : .green, "\(reading)")
        }
    }

    func test_greenChromeBrightensHeaderAndRingInDarkMode() {
        let light = QuranPageChromeStyle.green.palette(for: .light)
        let dark = QuranPageChromeStyle.green.palette(for: .dark)

        XCTAssertEqual(rgb(light.header), 0x047857)
        XCTAssertEqual(rgb(light.markerRing), 0x047857)
        XCTAssertEqual(rgb(dark.header), 0x10B981)
        XCTAssertEqual(rgb(dark.markerRing), 0x10B981)
    }

    func test_quietThemeUsesDarkPaletteEvenInLightColorScheme() {
        for style in [QuranPageChromeStyle.green, .blue] {
            XCTAssertEqual(style.palette(colorScheme: .light, themeStyle: .quiet), style.palette(for: .dark), "\(style)")
            XCTAssertEqual(style.palette(colorScheme: .light, themeStyle: .paper), style.palette(for: .light), "\(style)")
            XCTAssertEqual(style.palette(colorScheme: .dark, themeStyle: .paper), style.palette(for: .dark), "\(style)")
        }
    }

    private func rgb(_ color: Color) -> Int {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return (Int((red * 255).rounded()) << 16) | (Int((green * 255).rounded()) << 8) | Int((blue * 255).rounded())
    }
}
