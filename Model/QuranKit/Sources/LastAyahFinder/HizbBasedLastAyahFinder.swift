//
//  HizbBasedLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

/// Finds the last ayah of the hizb that contains the start ayah.
public struct HizbBasedLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        startAyah.quran.hizbs.binarySearchFirst { startAyah >= $0.firstVerse }.lastVerse
    }
}
