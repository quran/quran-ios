//
//  QuarterBasedLastAyahFinder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-01.
//

/// Finds the last ayah of the quarter (¼ hizb) that contains the start ayah.
public struct QuarterBasedLastAyahFinder: LastAyahFinder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func findLastAyah(startAyah: AyahNumber) -> AyahNumber {
        startAyah.quran.quarters.binarySearchFirst { startAyah >= $0.firstVerse }.lastVerse
    }
}
