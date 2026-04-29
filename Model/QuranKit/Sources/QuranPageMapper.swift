//
//  QuranPageMapper.swift
//
//
//  Created by OpenAI on 2026-04-25.
//

public struct QuranPageMapper {
    // MARK: Lifecycle

    public init(destination: Quran) {
        self.destination = destination
    }

    // MARK: Public

    public let destination: Quran

    public func mapPage(_ page: Page) -> Page? {
        mapAyah(page.firstVerse)?.page
    }

    public func mapAyah(_ ayah: AyahNumber) -> AyahNumber? {
        AyahNumber(quran: destination, sura: ayah.sura.suraNumber, ayah: ayah.ayah)
    }
}
