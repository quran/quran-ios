//
//  SuraHeaderLocation.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import CoreGraphics
import QuranKit

public struct SuraHeaderLocation {
    let sura: Sura
    let x: Int
    let y: Int
    let width: Int
    let height: Int

    public init(sura: Sura, x: Int, y: Int, width: Int, height: Int) {
        self.sura = sura
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    public var rect: CGRect {
        CGRect(x: x, y: y - height / 2, width: width, height: height)
    }
}
