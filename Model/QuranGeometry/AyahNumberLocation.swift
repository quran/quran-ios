//
//  AyahNumberLocation.swift
//
//
//  Created by Mohamed Afifi on 2023-06-10.
//

import CoreGraphics
import QuranKit

public struct AyahNumberLocation {
    // MARK: Lifecycle

    public init(ayah: AyahNumber, x: Int, y: Int) {
        self.ayah = ayah
        self.x = x
        self.y = y
    }

    // MARK: Public

    public let ayah: AyahNumber

    public func rect(ofLength length: CGFloat) -> CGRect {
        CGRect(x: CGFloat(x) - length / 2, y: CGFloat(y) - length / 2, width: length, height: length)
    }

    // MARK: Internal

    let x: Int
    let y: Int
}
