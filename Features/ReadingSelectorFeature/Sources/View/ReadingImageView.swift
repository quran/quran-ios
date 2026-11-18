//
//  ReadingImageView.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-04-23.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import NoorUI
import QuranGeometry
import QuranKit
import SwiftUI

struct ReadingImageView: View {
    let image: UIImage
    let reading: Reading

    var body: some View {
        content
            .aspectRatio(image.size, contentMode: .fit)
    }

    private var content: some View {
        AdaptiveImageScrollView(decorations: reading.previewDecorations) {
            image
        } onScaleChange: { _ in
        } onGlobalFrameChange: { _ in
        } header: {
        } footer: {
        }
    }
}

extension Reading {
    var previewDecorations: ImageDecorations {
        var decorations = ImageDecorations(
            suraHeaders: suraHeaders,
            ayahNumbers: ayahNumbers,
            drawsAyahNumbersAndSuraHeaders: true,
            chromeStyle: QuranPageChromeStyle(reading: self),
            wordFrames: WordFrameCollection(frames: [])
        )
        if usesLinePages {
            decorations.ayahNumberWidthRatio = LinePageGeometryEngine.ayahMarkerWidthRatio
        }
        return decorations
    }
}
