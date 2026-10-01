//
//  PreferencesLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2022-04-16.
//

import QuranKit

public struct PreferencesLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    private init() {
    }

    // MARK: Public

    public static let shared = PreferencesLastAyahFinder()

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        AudioEndLastAyahFinder(audioEnd: preferences.audioEnd).findLastAyah(startAyah: startAyah)
    }

    // MARK: Private

    private let preferences = AudioPreferences.shared
}
