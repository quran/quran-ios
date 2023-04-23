//
//  PageMarkers.swift
//
//
//  Created by Mohamed Afifi on 2023-04-19.
//

import CoreGraphics
import QuranKit

public struct PageMarkers {
    public let suraHeaders: [SuraHeaderLocation]
    public let ayahNumbers: [AyahNumberLocation]

    public init(suraHeaders: [SuraHeaderLocation], ayahNumbers: [AyahNumberLocation]) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
    }
}

public struct SuraHeaderLocation {
    let sura: Sura
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    public var rect: CGRect {
        CGRect(x: x, y: y - height / 2, width: width, height: height)
    }
}

public struct AyahNumberLocation {
    public let ayah: AyahNumber
    let x: Int
    let y: Int

    public func rect(ofLength length: CGFloat) -> CGRect {
        CGRect(x: CGFloat(x) - length / 2, y: CGFloat(y) - length / 2, width: length, height: length)
    }
}
