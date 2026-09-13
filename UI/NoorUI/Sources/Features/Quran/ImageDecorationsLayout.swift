//
//  ImageDecorationsLayout.swift
//

import QuranGeometry
import SwiftUI

/// Decoration rectangles in the image view's local coordinate space.
struct ImageDecorationsLayout {
    let highlights: [HighlightPlacement]
    let suraHeaders: [SuraHeaderPlacement]
    let ayahMarkers: [AyahMarkerPlacement]

    var drawnAyahMarkers: [AyahMarkerPlacement] {
        drawsAyahNumbersAndSuraHeaders ? ayahMarkers : []
    }

    private let drawsAyahNumbersAndSuraHeaders: Bool

    init(decorations: ImageDecorations, imageSize: CGSize, scale: WordFrameScale) {
        drawsAyahNumbersAndSuraHeaders = decorations.drawsAyahNumbersAndSuraHeaders
        ayahMarkers = decorations.ayahNumbers.map {
            AyahMarkerPlacement(ayah: $0.ayah, frame: $0.scaledRectangle(imageSize: imageSize, scale: scale))
        }
        suraHeaders = decorations.drawsAyahNumbersAndSuraHeaders ? decorations.suraHeaders.map {
            SuraHeaderPlacement(id: $0, frame: $0.rect.scaled(by: scale))
        } : []
        highlights = decorations.wordFrames.frames.map {
            HighlightPlacement(id: $0, frame: $0.rect.scaled(by: scale), color: decorations.highlights[$0] ?? .clear)
        }
    }

    struct HighlightPlacement: Identifiable {
        let id: WordFrame
        let frame: CGRect
        let color: Color
    }

    struct SuraHeaderPlacement: Identifiable {
        let id: SuraHeaderLocation
        let frame: CGRect
    }
}
