//
//  LinePageChromeStyle.swift
//

import QuranKit
import SwiftUI
import UIKit
import UIx

enum LinePageChromeStyle: Equatable {
    case greenChrome
    case blueChrome

    init(reading: Reading) {
        switch reading {
        case .hafs_1439:
            self = .blueChrome
        case .hafs_1405, .hafs_1421, .hafs_1440, .hafs_1441, .tajweed, .indoPak:
            self = .greenChrome
        }
    }
}

struct LinePageChromeColors {
    let foreground: Color
    let background: Color?
}

struct LinePageChromeMarkerPalette {
    let ringForeground: Color
    let content: LinePageChromeColors?
}

struct LinePageChromePalette {
    let header: LinePageChromeColors
    let marker: LinePageChromeMarkerPalette
}

private func color(hex: Int) -> Color {
    Color(uiColor: UIColor(rgb: hex))
}

extension LinePageChromeStyle {
    func palette(for colorScheme: ColorScheme) -> LinePageChromePalette {
        switch (self, colorScheme) {
        case (.blueChrome, .dark):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x73AFFA), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x73AFFA),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x73AFFA),
                        background: color(hex: 0x172554)
                    )
                )
            )
        case (.blueChrome, .light):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x2563EB), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x2563EB),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x1D4ED8),
                        background: color(hex: 0xEFF6FF)
                    )
                )
            )
        case (.greenChrome, .dark):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x047857), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x047857),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x34D399),
                        background: color(hex: 0x022C22)
                    )
                )
            )
        case (.greenChrome, .light):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x047857), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x047857),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x047857),
                        background: color(hex: 0xECFDF5)
                    )
                )
            )
        @unknown default:
            return palette(for: .light)
        }
    }
}
