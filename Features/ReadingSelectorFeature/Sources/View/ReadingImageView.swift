//
//  ReadingImageView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-23.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import NoorUI
import QuranGeometry
import SwiftUI

struct ReadingImageView: View {
    let image: UIImage
    let suraHeaders: [SuraHeaderLocation]
    let ayahNumbers: [AyahNumberLocation]
    let renderingMode: QuranThemedImage.RenderingMode

    var body: some View {
        content
            .aspectRatio(image.size, contentMode: .fit)
    }

    private var content: some View {
        #if QURAN_SYNC
        AdaptiveImageScrollView(decorations: decorations, renderingMode: renderingMode, ayahAnnotations: [:]) {
            image
        } onAnnotatedAyahTap: { _, _ in
        } onScaleChange: { _ in
        } onGlobalFrameChange: { _ in
        } header: {
        } footer: {
        }
        #else
        AdaptiveImageScrollView(decorations: decorations, renderingMode: renderingMode) {
            image
        } onScaleChange: { _ in
        } onGlobalFrameChange: { _ in
        } header: {
        } footer: {
        }
        #endif
    }

    private var decorations: ImageDecorations {
        ImageDecorations(
            suraHeaders: suraHeaders,
            ayahNumbers: ayahNumbers,
            drawsAyahNumbersAndSuraHeaders: true,
            wordFrames: WordFrameCollection(frames: []),
            highlights: [:]
        )
    }
}
