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

    private func quranPageColorScheme(colorScheme: ColorScheme, themeStyle: ThemeStyle) -> ColorScheme {
        var environment = EnvironmentValues()
        environment.colorScheme = colorScheme
        environment.themeStyle = themeStyle
        return environment.quranPageColorScheme
    }
}
