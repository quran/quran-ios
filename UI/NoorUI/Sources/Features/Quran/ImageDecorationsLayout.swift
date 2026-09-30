//
//  ImageDecorationsLayout.swift
//

import QuranAnnotations
import QuranGeometry
import QuranKit
import SwiftUI

/// Decoration rectangles in the image view's local coordinate space.
struct ImageDecorationsLayout {
    let verseHighlights: [VerseHighlightPlacement]
    let wordHighlight: WordHighlightPlacement?
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
        verseHighlights = decorations.verseHighlights
            .sorted { $0.key < $1.key }
            .compactMap { verse, color in
                let lineRects = Self.lineRects(of: decorations.wordFrames.wordFramesForVerse(verse), scale: scale)
                return lineRects.isEmpty ? nil : VerseHighlightPlacement(id: verse, lineRects: lineRects, color: color)
            }
        wordHighlight = decorations.wordHighlight
            .flatMap { decorations.wordFrames.wordFrameForWord($0) }
            .map { WordHighlightPlacement(frame: $0.rect.scaled(by: scale), color: VerseOverlays.wordHighlightColor) }
    }

    struct VerseHighlightPlacement: Identifiable {
        let id: AyahNumber
        /// The union of the verse's word frames on each line, top to bottom.
        let lineRects: [CGRect]
        let color: Color
    }

    struct WordHighlightPlacement {
        let frame: CGRect
        let color: Color
    }

    struct SuraHeaderPlacement: Identifiable {
        let id: SuraHeaderLocation
        let frame: CGRect
    }

    private static func lineRects(of frames: [WordFrame], scale: WordFrameScale) -> [CGRect] {
        Dictionary(grouping: frames, by: \.line)
            .sorted { $0.key < $1.key }
            .map { _, frames in
                frames.map(\.rect).reduce(CGRect.null) { $0.union($1) }.scaled(by: scale)
            }
    }
}
