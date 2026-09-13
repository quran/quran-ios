//
//  AyahMarkerPlacement.swift
//

import CoreGraphics
import QuranKit

/// An ayah marker's rectangle in the page drawing and annotation layers' local coordinate space.
public struct AyahMarkerPlacement: Hashable {
    public init(ayah: AyahNumber, frame: CGRect) {
        self.ayah = ayah
        self.frame = frame
    }

    let ayah: AyahNumber
    let frame: CGRect
}
