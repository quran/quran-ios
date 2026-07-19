//
//  SuraHeaderLocation.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import CoreGraphics
import QuranKit

public struct SuraHeaderLocation: Hashable {
    // MARK: Lifecycle

    public init(sura: Sura, x: Int, y: Int, width: Int, height: Int) {
        self.sura = sura
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    // MARK: Public

    public var rect: CGRect {
        CGRect(x: x, y: y - height / 2, width: width, height: height)
    }

    // MARK: Internal

    let sura: Sura
    let x: Int
    let y: Int
    let width: Int
    let height: Int
}
