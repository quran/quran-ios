//
//  AyahTiming.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
//

import QuranKit

public struct AyahTiming {
    // MARK: Lifecycle

    public init(ayah: AyahNumber, time: Timing) {
        self.ayah = ayah
        self.time = time
    }

    // MARK: Public

    public let ayah: AyahNumber
    public let time: Timing
}
