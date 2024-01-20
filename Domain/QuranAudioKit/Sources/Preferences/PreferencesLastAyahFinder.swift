//
//  PreferencesLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Foundation
import QuranKit

public struct PreferencesLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    private init() {
    }

    // MARK: Public

    public static let shared = PreferencesLastAyahFinder()

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        let pageLastVerse = pageFinder.findLastAyah(startAyah: startAyah)
        let lastVerse = finder.findLastAyah(startAyah: startAyah)
        return max(lastVerse, pageLastVerse)
    }

    // MARK: Private

    private let preferences = AudioPreferences.shared

    private var finder: LastAyahFinder {
        switch preferences.audioEnd {
        case .juz:
            return JuzBasedLastAyahFinder()
        case .sura:
            return SuraBasedLastAyahFinder()
        case .page:
            return pageFinder
        }
    }

    private var pageFinder: LastAyahFinder {
        PageBasedLastAyahFinder()
    }
}
