//
//  LinePageModels.swift
//
//
//  Created by Mohamed Afifi on 2026-03-28.
//

import QuranKit

public struct LinePageHighlightSpan: Hashable, Sendable {
    public init(ayah: AyahNumber, line: Int, left: Double, right: Double) {
        self.ayah = ayah
        self.line = line
        self.left = left
        self.right = right
    }

    public let ayah: AyahNumber
    public let line: Int
    public let left: Double
    public let right: Double
}

public struct LinePageAyahMarker: Hashable, Sendable {
    public init(ayah: AyahNumber, line: Int, centerX: Double, centerY: Double, codePoint: String) {
        self.ayah = ayah
        self.line = line
        self.centerX = centerX
        self.centerY = centerY
        self.codePoint = codePoint
    }

    public let ayah: AyahNumber
    public let line: Int
    public let centerX: Double
    public let centerY: Double
    public let codePoint: String
}

public struct LinePageSuraHeader: Hashable, Sendable {
    public init(sura: Sura, line: Int, centerX: Double, centerY: Double) {
        self.sura = sura
        self.line = line
        self.centerX = centerX
        self.centerY = centerY
    }

    public let sura: Sura
    public let line: Int
    public let centerX: Double
    public let centerY: Double
}
