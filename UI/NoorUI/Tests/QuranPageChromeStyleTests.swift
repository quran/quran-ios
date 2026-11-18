import SwiftUI
import XCTest
@testable import NoorUI

final class QuranPageChromeStyleTests: XCTestCase {
    func test_quietThemeUsesDarkPaletteEvenInLightColorScheme() {
        XCTAssertEqual(quranPageColorScheme(colorScheme: .light, themeStyle: .quiet), .dark)
        XCTAssertEqual(quranPageColorScheme(colorScheme: .light, themeStyle: .paper), .light)
        XCTAssertEqual(quranPageColorScheme(colorScheme: .dark, themeStyle: .paper), .dark)
    }

    private func quranPageColorScheme(colorScheme: ColorScheme, themeStyle: ThemeStyle) -> ColorScheme {
        var environment = EnvironmentValues()
        environment.colorScheme = colorScheme
        environment.themeStyle = themeStyle
        return environment.quranPageColorScheme
    }
}
