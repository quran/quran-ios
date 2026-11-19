import QuranKit
import SwiftUI
import XCTest
@testable import NoorUI

final class QuranPageChromeStyleTests: XCTestCase {
    func test_quietThemeUsesDarkPaletteEvenInLightColorScheme() {
        XCTAssertEqual(quranPageColorScheme(colorScheme: .light, themeStyle: .quiet), .dark)
        XCTAssertEqual(quranPageColorScheme(colorScheme: .light, themeStyle: .paper), .light)
        XCTAssertEqual(quranPageColorScheme(colorScheme: .dark, themeStyle: .paper), .dark)
    }

    func test_hafs1421UsesBronzeStyle() {
        XCTAssertEqual(QuranPageChromeStyle(reading: .hafs_1421), .bronze)
    }

    func test_cappedColor_matchesTextLuminanceAndKeepsHue_andDarkerColorsAreUnchanged() {
        let text = UIColor(red: 0x8D / 255, green: 0x8D / 255, blue: 0x92 / 255, alpha: 1)
        let bright = UIColor(red: 0x10 / 255, green: 0xB9 / 255, blue: 0x81 / 255, alpha: 1)
        let capped = bright.capped(atLuminanceOf: text)

        XCTAssertEqual(capped.relativeLuminance, text.relativeLuminance, accuracy: 0.0001)
        XCTAssertLessThan(capped.relativeLuminance, bright.relativeLuminance)
        XCTAssertEqual(hue(of: capped), hue(of: bright), accuracy: 0.002)

        let dark = UIColor(red: 0x02 / 255, green: 0x2C / 255, blue: 0x22 / 255, alpha: 1)
        XCTAssertTrue(dark.capped(atLuminanceOf: text) === dark)
    }

    private func hue(of color: UIColor) -> CGFloat {
        var hue: CGFloat = 0
        color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil)
        return hue
    }

    private func quranPageColorScheme(colorScheme: ColorScheme, themeStyle: ThemeStyle) -> ColorScheme {
        var environment = EnvironmentValues()
        environment.colorScheme = colorScheme
        environment.themeStyle = themeStyle
        return environment.quranPageColorScheme
    }
}
