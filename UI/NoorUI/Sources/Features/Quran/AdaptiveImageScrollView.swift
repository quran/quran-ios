//
//  AdaptiveImageScrollView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-17.
//

import QuranAnnotations
import QuranGeometry
import QuranKit
import SwiftUI
import UIx

/// `AdaptiveImageScrollView` adjusts an image to fill the available space and enables scrolling
/// when the view's width is greater than its height. In contrast, it fits the image within the view
/// without scrolling when the view's height is greater than its width.
public struct AdaptiveImageScrollView<Header: View, Footer: View>: View {
    // MARK: Lifecycle

    #if !QURAN_SYNC
    public init(
        decorations: ImageDecorations,
        renderingMode: QuranThemedImage.RenderingMode = .tinted,
        image: () -> UIImage?,
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.decorations = decorations
        self.image = image()
        self.renderingMode = renderingMode
        self.header = header()
        self.footer = footer()
        self.onScaleChange = onScaleChange
        self.onGlobalFrameChange = onGlobalFrameChange
    }
    #else
    public init(
        decorations: ImageDecorations,
        renderingMode: QuranThemedImage.RenderingMode = .tinted,
        ayahIndicators: [AyahNumber: Set<AyahIndicator>],
        indicatorsHidden: Bool,
        image: () -> UIImage?,
        onAyahIndicatorTap: @escaping (AyahNumber, CGPoint) -> Void,
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.ayahIndicators = ayahIndicators
        self.indicatorsHidden = indicatorsHidden
        self.onAyahIndicatorTap = onAyahIndicatorTap
        self.decorations = decorations
        self.image = image()
        self.renderingMode = renderingMode
        self.header = header()
        self.footer = footer()
        self.onScaleChange = onScaleChange
        self.onGlobalFrameChange = onGlobalFrameChange
    }
    #endif

    // MARK: Public

    public var body: some View {
        AdaptiveQuranScrollView {
            header
        } footer: {
            footer
        } content: { availableContentSize in
            Group {
                if let image {
                    imageContent(image)
                } else {
                    Color.clear
                }
            }
            .frame(height: imageHeight(for: availableContentSize))
        }
    }

    // MARK: Private

    private let header: Header
    private let footer: Footer
    private let image: UIImage?
    private let renderingMode: QuranThemedImage.RenderingMode
    private let decorations: ImageDecorations
    @State private var imageViewSize: CGSize = .zero
    #if QURAN_SYNC
    private let ayahIndicators: [AyahNumber: Set<AyahIndicator>]
    private let indicatorsHidden: Bool
    private let onAyahIndicatorTap: (AyahNumber, CGPoint) -> Void
    #endif
    private let onScaleChange: (WordFrameScale) -> Void
    private let onGlobalFrameChange: (CGRect) -> Void

    private struct SizeInfo: Equatable {
        let imageSize: CGSize
        let viewSize: CGSize
    }

    private func imageContent(_ image: UIImage) -> some View {
        let sizeInfo = SizeInfo(imageSize: image.size, viewSize: imageViewSize)
        let scale = WordFrameScale.scaling(imageSize: sizeInfo.imageSize, into: sizeInfo.viewSize)
        let layout = ImageDecorationsLayout(decorations: decorations, imageSize: image.size, scale: scale)

        return QuranThemedImage(image: image, renderingMode: renderingMode)
            .background {
                ZStack(alignment: .topLeading) {
                    AyahScrollAnchorsView(wordFrames: decorations.wordFrames, scale: scale)
                    ImageDecorationsView(layout: layout)
                }
            }
            .onGlobalFrameChanged { frame in
                if imageViewSize != frame.size {
                    imageViewSize = frame.size
                }
                onGlobalFrameChange(frame)
            }
            .onChangeWithInitial(of: sizeInfo) { sizeInfo in
                onScaleChange(WordFrameScale.scaling(
                    imageSize: sizeInfo.imageSize,
                    into: sizeInfo.viewSize
                ))
            }
            .allowsHitTesting(false)
        #if QURAN_SYNC
            .overlay {
                AyahIndicatorsView(
                    markers: layout.ayahMarkers,
                    indicators: ayahIndicators,
                    indicatorsHidden: indicatorsHidden,
                    onAyahIndicatorTap: onAyahIndicatorTap
                )
            }
        #endif
    }

    private func imageHeight(for availableContentSize: CGSize) -> CGFloat {
        if let imageSize = image?.size, availableContentSize.width > availableContentSize.height {
            return availableContentSize.width * (imageSize.height / imageSize.width)
        } else {
            return availableContentSize.height
        }
    }
}

#if QURAN_SYNC
private struct IndicatedAyahImagePreview: View {
    var body: some View {
        AdaptiveImageScrollView(
            decorations: decorations,
            ayahIndicators: ayah.map { [$0: [.collection, .note]] } ?? [:],
            indicatorsHidden: false
        ) {
            UIImage(contentsOfFile: testResourceURL("images/page604.png").path)
        } onAyahIndicatorTap: { _, _ in tapCount += 1
        } onScaleChange: { _ in
        } onGlobalFrameChange: { _ in
        } header: {
            QuranPageHeader(quarterName: "Juz 30", suras: Quran.hafsMadani1405.pages[603].suras)
        } footer: {
            QuranPageFooter(page: "604")
        }
        .font(.footnote)
        .populateReadableInsets()
        .overlay(alignment: .bottom) {
            Text(tapCount == 0 ? "Tap the indicator icons" : "Ayah menu tapped \(tapCount) time\(tapCount == 1 ? "" : "s")")
                .font(.footnote.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .padding(.bottom, 44)
        }
        .themedBackground()
        .ignoresSafeArea()
        .environment(\.themeStyle, .paper)
    }

    private var decorations: ImageDecorations {
        guard let ayah else {
            return ImageDecorations(
                suraHeaders: [],
                ayahNumbers: [],
                drawsAyahNumbersAndSuraHeaders: false,
                wordFrames: WordFrameCollection(frames: [])
            )
        }

        return ImageDecorations(
            suraHeaders: [],
            // Final glyph center for 112:1 on page 604 in hafs_1405_ayahinfo.db.
            ayahNumbers: [AyahNumberLocation(ayah: ayah, x: 768, y: 342)],
            drawsAyahNumbersAndSuraHeaders: false,
            wordFrames: WordFrameCollection(frames: [])
        )
    }

    @State private var tapCount = 0
    private let ayah = AyahNumber(quran: .hafsMadani1405, sura: 112, ayah: 1)
}

#Preview("Ayah indicator on Madani 1405") {
    IndicatedAyahImagePreview()
}

#endif
