//
//  ImageDecorationsView.swift
//
//
//  Created by Mohamed Afifi on 2024-04-02.
//

import QuranGeometry
import SwiftUI

public struct ImageDecorations {
    public var suraHeaders: [SuraHeaderLocation]
    public var ayahNumbers: [AyahNumberLocation]
    public var wordFrames: WordFrameCollection
    public var highlights: [WordFrame: Color]

    public init(
        suraHeaders: [SuraHeaderLocation],
        ayahNumbers: [AyahNumberLocation],
        wordFrames: WordFrameCollection,
        highlights: [WordFrame: Color]
    ) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
        self.wordFrames = wordFrames
        self.highlights = highlights
    }
}

struct ImageDecorationsView: View {
    private struct SizeInfo: Equatable {
        var imageSize: CGSize
        var viewSize: CGSize
    }

    // MARK: Internal

    let imageSize: CGSize
    let decorations: ImageDecorations
    let onScaleChange: (WordFrameScale) -> Void
    let onGlobalFrameChange: (CGRect) -> Void

    var scale: WordFrameScale {
        WordFrameScale.scaling(imageSize: sizeInfo.imageSize, into: sizeInfo.viewSize)
    }

    var highlights: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(decorations.wordFrames.lines.enumerated()), id: \.element) { item in
                let line = item.element
                let index = item.offset
                ZStack(alignment: .topLeading) {
                    // Needed to ensure ZStack takes full width.
                    Spacer()
                        .frame(maxWidth: .infinity, maxHeight: 0)

                    ForEach(line.frames, id: \.self) { frame in
                        let color = decorations.highlights[frame] ?? .clear
                        let scaledRectangle = frame.rect.scaled(by: scale)
                        color
                            .offset(x: scaledRectangle.minX)
                            .frame(width: scaledRectangle.width, height: scaledRectangle.height)
                    }
                }
                .padding(.top, decorations.wordFrames.topPadding(atLineIndex: index, scale: scale))
            }
        }
        .padding(.top, scale.yOffset)
    }

    var suraHeaders: some View {
        ForEach(decorations.suraHeaders, id: \.self) { suraHeader in
            let scaledRectangle = suraHeader.rect.scaled(by: scale)
            SuraHeaderView()
                .offset(x: scaledRectangle.minX, y: scaledRectangle.minY)
                .frame(width: scaledRectangle.width, height: scaledRectangle.height)
        }
    }

    var ayahNumbers: some View {
        ForEach(decorations.ayahNumbers, id: \.self) { ayahNumber in
            let length = 0.06 * imageSize.width
            let scaledRectangle = CGRect(
                x: ayahNumber.center.x - length / 2,
                y: ayahNumber.center.y - length / 2,
                width: length,
                height: length
            ).scaled(by: scale)
            AyahNumberView(number: ayahNumber.ayah.ayah)
                .offset(x: scaledRectangle.minX, y: scaledRectangle.minY)
                .frame(width: scaledRectangle.width, height: scaledRectangle.height)
        }
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                highlights
                suraHeaders
                ayahNumbers
            }
        }
        .onChangeWithInitial(of: imageSize) { sizeInfo.imageSize = $0 }
        .onSizeChange { sizeInfo.viewSize = $0 }
        .onChange(of: sizeInfo) { newSizeInfo in
            onScaleChange(.scaling(imageSize: newSizeInfo.imageSize, into: newSizeInfo.viewSize))
        }
        .onGlobalFrameChanged(onGlobalFrameChange)
    }

    // MARK: Private

    @State private var sizeInfo: SizeInfo = SizeInfo(imageSize: .zero, viewSize: .zero)
}

private struct SuraHeaderView: View {
    public var body: some View {
        NoorImage.suraHeader.image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.pageMarkerTint)
    }
}

private struct AyahNumberView: View {
    let number: Int

    public var body: some View {
        NoorImage.ayahEnd.image
            .resizable()
            .padding(.horizontal, 1)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(.pageMarkerTint)
            .overlay(
                Text(NumberFormatter.arabicNumberFormatter.format(number))
                    .font(.largeTitle)
                    .minimumScaleFactor(0.03)
                    .padding(3)
            )
    }
}

#Preview {
    List {
        SuraHeaderView()
            .frame(height: 40)

        AyahNumberView(number: 1)
            .frame(height: 40)
        AyahNumberView(number: 2)
            .frame(height: 40)

        AyahNumberView(number: 100)
            .frame(height: 40)

        AyahNumberView(number: 999)
            .frame(height: 40)
    }
}
