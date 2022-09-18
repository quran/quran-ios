//
//  PreferencesLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import Foundation
import QuranKit

@available(iOS 13.0, *)
public struct PreferencesLastAyahFinder: LastAyahFinder {
    public static let shared = PreferencesLastAyahFinder()
    private init() {
    }

    private let preferences = AudioPreferences.shared

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        let pageLastVerse = pageFinder.findLastAyah(startAyah: startAyah)
        let lastVerse = finder.findLastAyah(startAyah: startAyah)
        return max(lastVerse, pageLastVerse)
    }

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
