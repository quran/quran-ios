//
//  AyahScrollAnchorsView.swift
//

import QuranGeometry
import QuranKit
import SwiftUI

public struct AyahScrollAnchorsView: View {
    public init(wordFrames: WordFrameCollection, scale: WordFrameScale) {
        anchors = wordFrames.verseStartFrames.map { frame in
            AyahScrollAnchor(ayah: frame.word.verse, y: frame.rect.scaled(by: scale).minY)
        }
    }

    public init(wordFrames: WordFrameCollection, layout: LinePageLayout) {
        anchors = wordFrames.verseStartFrames.compactMap { frame in
            guard let start = layout.selectionAnchors(for: frame.word.verse)?.start else { return nil }
            return AyahScrollAnchor(ayah: frame.word.verse, y: start.minY)
        }
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(anchors, id: \.ayah) { anchor in
                // Give the ayah target its own bounds, separate from the space above it.
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: anchor.y)

                    Color.clear
                        .frame(width: 1, height: 1)
                        .id(AyahScrollTarget(ayah: anchor.ayah))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.layoutDirection, .leftToRight)
        .allowsHitTesting(false)
    }

    private let anchors: [AyahScrollAnchor]

    private struct AyahScrollAnchor {
        let ayah: AyahNumber
        let y: CGFloat
    }
}

/// Distinguishes scroll destinations from other views identified by the same ayah.
public struct AyahScrollTarget: Hashable {
    public init(ayah: AyahNumber) {
        self.ayah = ayah
    }

    private let ayah: AyahNumber
}
