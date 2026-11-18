//
//  QuranPageChromeStyle.swift
//

import QuranKit
import SwiftUI
import UIKit
import UIx

/// The colors of the sura headers and ayah markers the app draws on Quran pages.
public enum QuranPageChromeStyle: Equatable {
    case green
    case blue

    // MARK: Lifecycle

    public init(reading: Reading) {
        switch reading {
        case .hafs_1439:
            self = .blue
        case .hafs_1405, .hafs_1421, .hafs_1440, .hafs_1441, .tajweed, .indoPak:
            self = .green
        }
    }

    // MARK: Public

    public func palette(for colorScheme: ColorScheme) -> QuranPageChromePalette {
        switch (self, colorScheme) {
        case (.blue, .dark):
            QuranPageChromePalette(header: 0x73AFFA, markerRing: 0x73AFFA, markerFill: 0x172554, markerText: 0x73AFFA)
        case (.blue, _):
            QuranPageChromePalette(header: 0x2563EB, markerRing: 0x2563EB, markerFill: 0xEFF6FF, markerText: 0x1D4ED8)
        case (.green, .dark):
            QuranPageChromePalette(header: 0x10B981, markerRing: 0x10B981, markerFill: 0x022C22, markerText: 0x34D399)
        case (.green, _):
            QuranPageChromePalette(header: 0x047857, markerRing: 0x047857, markerFill: 0xECFDF5, markerText: 0x047857)
        }
    }
}

public struct QuranPageChromePalette: Equatable {
    // MARK: Lifecycle

    init(header: Int, markerRing: Int, markerFill: Int, markerText: Int) {
        self.header = Self.color(header)
        self.markerRing = Self.color(markerRing)
        self.markerFill = Self.color(markerFill)
        self.markerText = Self.color(markerText)
    }

    // MARK: Public

    public let header: Color
    public let markerRing: Color
    public let markerFill: Color
    public let markerText: Color

    // MARK: Private

    private static func color(_ rgb: Int) -> Color {
        Color(uiColor: UIColor(rgb: rgb))
    }
}
