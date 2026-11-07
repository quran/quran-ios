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
        ayahReadingBookmarks: [AyahNumber: [ReadingBookmarkSlot]] = [:],
        image: () -> UIImage?,
        onAyahReadingBookmarkTap: @escaping (AyahNumber, CGPoint) -> Void = { _, _ in },
        onScaleChange: @escaping (WordFrameScale) -> Void,
        onGlobalFrameChange: @escaping (CGRect) -> Void,
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer
    ) {
        self.ayahReadingBookmarks = ayahReadingBookmarks
        self.onAyahReadingBookmarkTap = onAyahReadingBookmarkTap
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
        GeometryReader { geometry in
            // iPhone Duo only: iPhone and iPad keep their page layout.
            let isLimitedByHeight = isLimitedByHeight(geometry.size) && windowHasVerticalBar
            AdaptiveQuranScrollView {
                header
            } footer: {
                footer
            } content: { availableContentSize in
                Group {
                    if let image {
                        imageContent(image, visibleRect: visibleRect(of: image, trimsMargins: isLimitedByHeight))
                    } else {
                        Color.clear
                    }
                }
                .frame(height: imageHeight(for: availableContentSize))
            }
            .environment(\.compactsPageChrome, isLimitedByHeight)
        }
    }

    // MARK: Private

    private let header: Header
    private let footer: Footer
    private let image: UIImage?
    private let renderingMode: QuranThemedImage.RenderingMode
    private let decorations: ImageDecorations
    @State private var imageViewSize: CGSize = .zero
    @Environment(\.windowHasVerticalBar) private var windowHasVerticalBar
    #if QURAN_SYNC
    private let ayahReadingBookmarks: [AyahNumber: [ReadingBookmarkSlot]]
    private let onAyahReadingBookmarkTap: (AyahNumber, CGPoint) -> Void
    @State private var pressedReadingBookmarkAyah: AyahNumber?
    #endif
    private let onScaleChange: (WordFrameScale) -> Void
    private let onGlobalFrameChange: (CGRect) -> Void

    private struct SizeInfo: Equatable {
        let imageSize: CGSize
        let visibleRect: CGRect
        let viewSize: CGSize

        var scale: WordFrameScale {
            WordFrameScale.scaling(imageSize: imageSize, visibleRect: visibleRect, into: viewSize)
        }
    }

    /// The part of the image to show. Where the page's height limits its size, the image's own blank
    /// margins are trimmed, so the Quran text gets bigger.
    private func visibleRect(of image: UIImage, trimsMargins: Bool) -> CGRect {
        guard trimsMargins else {
            return CGRect(origin: .zero, size: image.size)
        }
        let contentFrames = decorations.wordFrames.frames.map(\.rect)
            + decorations.suraHeaders.map(\.rect)
        return PageMarginTrimming.visibleRect(imageSize: image.size, contentFrames: contentFrames)
    }

    private func imageContent(_ image: UIImage, visibleRect: CGRect) -> some View {
        let sizeInfo = SizeInfo(imageSize: image.size, visibleRect: visibleRect, viewSize: imageViewSize)
        let scale = sizeInfo.scale
        let layout = ImageDecorationsLayout(decorations: decorations, imageSize: image.size, scale: scale)

        // The view has the visible part's shape. The image is placed so that part fills the view.
        return Color.clear
            .aspectRatio(visibleRect.width / visibleRect.height, contentMode: .fit)
            .overlay(alignment: .topLeading) {
                QuranThemedImage(image: image, renderingMode: renderingMode)
                    .frame(width: image.size.width * scale.scale, height: image.size.height * scale.scale)
                    .offset(x: scale.xOffset, y: scale.yOffset)
            }
            .clipped()
            .background {
                ZStack(alignment: .topLeading) {
                    AyahScrollAnchorsView(wordFrames: decorations.wordFrames, scale: scale)
                    ImageDecorationsView(layout: layout)
                    #if QURAN_SYNC
                    // Behind the image, so underlines never cover Quran text.
                    AyahReadingBookmarkUnderlines(
                        markers: layout.ayahMarkers,
                        bookmarks: ayahReadingBookmarks,
                        pressedAyah: pressedReadingBookmarkAyah
                    )
                    #endif
                }
            }
            .onGlobalFrameChanged { frame in
                if imageViewSize != frame.size {
                    imageViewSize = frame.size
                }
                onGlobalFrameChange(frame)
            }
            .onChangeWithInitial(of: sizeInfo) { sizeInfo in
                onScaleChange(sizeInfo.scale)
            }
            .allowsHitTesting(false)
        #if QURAN_SYNC
            .overlay {
                AyahReadingBookmarkTargets(
                    markers: layout.ayahMarkers,
                    bookmarks: ayahReadingBookmarks,
                    pressedAyah: $pressedReadingBookmarkAyah,
                    onTap: onAyahReadingBookmarkTap
                )
            }
        #endif
    }

    /// Whether the page fits its height and leaves room at the sides, so every point the header
    /// and footer give back makes the page bigger. Each page of a two-page spread is like that.
    private func isLimitedByHeight(_ size: CGSize) -> Bool {
        guard let imageSize = image?.size, imageSize.height > 0, size.height > 0, size.width <= size.height else {
            return false
        }
        return size.width / size.height > imageSize.width / imageSize.height
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
            ayahReadingBookmarks: ayah.map { [$0: [.teal, .red]] } ?? [:]
        ) {
            UIImage(contentsOfFile: testResourceURL("images/page604.png").path)
        } onAyahReadingBookmarkTap: { _, _ in tapCount += 1
        } onScaleChange: { _ in
        } onGlobalFrameChange: { _ in
        } header: {
            QuranPageHeader(quarterName: "Juz 30", suras: Quran.hafsMadani1405.pages[603].suras)
                .pageReadingBookmarkRibbons(page: Quran.hafsMadani1405.pages[603], slots: [.orange]) { _ in
                    ribbonTapCount += 1
                }
        } footer: {
            QuranPageFooter(page: "604")
        }
        .font(.footnote)
        .populateReadableInsets()
        .overlay(alignment: .bottom) {
            Text("Ayah menu tapped \(tapCount) time\(tapCount == 1 ? "" : "s"), ribbon \(ribbonTapCount)")
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
    @State private var ribbonTapCount = 0
    private let ayah = AyahNumber(quran: .hafsMadani1405, sura: 112, ayah: 1)
}

#Preview("Reading bookmark underline and ribbon on Madani 1405") {
    IndicatedAyahImagePreview()
}

#endif
