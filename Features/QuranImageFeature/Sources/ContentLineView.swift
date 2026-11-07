//
//  ContentLineView.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import ImageService
import NoorUI
import QuranAnnotations
import QuranGeometry
import QuranKit
import QuranLocalization
import QuranPagesFeature
import SwiftUI
import UIKit
import UIx

struct ContentLineView: View {
    @StateObject var viewModel: ContentLineViewModel
    #if QURAN_SYNC
    let onAyahReadingBookmarkTap: (AyahNumber, CGPoint) -> Void
    let onPageReadingBookmarkTap: (CGRect) -> Void
    #endif

    var body: some View {
        #if QURAN_SYNC
        let content = ContentLineViewBody(
            page: viewModel.page,
            layoutForSize: { viewModel.layout(for: $0, showHeaderFooter: false, usesDenseLines: $1) },
            scrollToVerse: viewModel.scrollToVerse,
            onReaderScroll: { viewModel.onReaderScroll() },
            wordFrames: viewModel.wordFrames,
            highlightColorsByVerse: viewModel.highlightColorsByVerse,
            undimmedVerses: viewModel.undimmedVerses,
            ayahReadingBookmarks: viewModel.ayahReadingBookmarks,
            pageReadingBookmarks: viewModel.pageReadingBookmarks,
            drawsAyahNumbersAndSuraHeaders: viewModel.drawsAyahNumbersAndSuraHeaders,
            chromeStyle: viewModel.chromeStyle,
            imageForLine: viewModel.lineImage(for:),
            imageForSideline: viewModel.sidelineImage(for:),
            onAyahReadingBookmarkTap: onAyahReadingBookmarkTap,
            onPageReadingBookmarkTap: onPageReadingBookmarkTap,
            onGlobalFrameChange: viewModel.updateContentFrame
        )
        #else
        let content = ContentLineViewBody(
            page: viewModel.page,
            layoutForSize: { viewModel.layout(for: $0, showHeaderFooter: false, usesDenseLines: $1) },
            scrollToVerse: viewModel.scrollToVerse,
            onReaderScroll: { viewModel.onReaderScroll() },
            wordFrames: viewModel.wordFrames,
            highlightColorsByVerse: viewModel.highlightColorsByVerse,
            undimmedVerses: viewModel.undimmedVerses,
            drawsAyahNumbersAndSuraHeaders: viewModel.drawsAyahNumbersAndSuraHeaders,
            chromeStyle: viewModel.chromeStyle,
            imageForLine: viewModel.lineImage(for:),
            imageForSideline: viewModel.sidelineImage(for:),
            onGlobalFrameChange: viewModel.updateContentFrame
        )
        #endif
        return content
            .geometryActions(
                PageGeometryActions(
                    id: ObjectIdentifier(viewModel),
                    word: { _ in nil },
                    verse: { point in viewModel.verseAtGlobalPoint(point) }
                )
            )
            .onAppear { viewModel.onAppear() }
            .onDisappear { viewModel.onDisappear() }
            .task {
                await viewModel.loadLinePage()
            }
    }
}

private struct ContentLineViewBody: View {
    // MARK: Internal

    let page: Page
    /// The layout for an available size, and whether lines may sit closer together.
    let layoutForSize: (CGSize, Bool) -> LinePageLayout?
    let scrollToVerse: AyahNumber?
    let onReaderScroll: () -> Void
    let wordFrames: WordFrameCollection
    let highlightColorsByVerse: [AyahNumber: Color]
    let undimmedVerses: Set<AyahNumber>?
    #if QURAN_SYNC
    let ayahReadingBookmarks: [AyahNumber: [ReadingBookmarkSlot]]
    let pageReadingBookmarks: [ReadingBookmarkSlot]
    #endif
    let drawsAyahNumbersAndSuraHeaders: Bool
    let chromeStyle: QuranPageChromeStyle
    let imageForLine: (Int) -> UIImage?
    let imageForSideline: (String) -> UIImage?
    #if QURAN_SYNC
    let onAyahReadingBookmarkTap: (AyahNumber, CGPoint) -> Void
    let onPageReadingBookmarkTap: (CGRect) -> Void
    #endif
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        GeometryReader { geometry in
            AdaptiveQuranScrollView {
                QuranPageHeader(
                    quarterName: page.localizedQuarterName,
                    suras: page.suras
                )
                #if QURAN_SYNC
                .pageReadingBookmarkRibbons(page: page, slots: pageReadingBookmarks, onTap: onPageReadingBookmarkTap)
                #endif
            } footer: {
                QuranPageFooter(page: page.localizedNumber)
            } content: { availableContentSize in
                // Denser lines only on iPhone Duo, so iPhone and iPad keep their page layout.
                VerticalBarReader { windowHasVerticalBar in
                    lineCanvas(layoutForSize(availableContentSize, windowHasVerticalBar))
                }
            }
            .compactsPageChromeOnVerticalBarDisplays(isLimitedByHeight: isLimitedByHeight(geometry.size))
        }
        .font(.footnote)
        .populateReadableInsets()
        .themedBackground()
        .quranScrolling(scrollToValue: scrollToVerse, onReaderScroll: onReaderScroll) { AyahScrollTarget(ayah: $0) }
    }

    // MARK: Private

    @Environment(\.quranPageColorScheme) private var quranPageColorScheme
    @Environment(\.themeColors) private var themeColors
    @Environment(\.displayScale) private var displayScale
    #if QURAN_SYNC
    @State private var pressedReadingBookmarkAyah: AyahNumber?
    #endif

    private var chromePalette: QuranPageChromePalette {
        chromeStyle.palette(for: quranPageColorScheme, text: themeColors.text)
    }

    /// Whether the page's height limits its size, so the header and page number use tighter spacing.
    /// Line pages are at least 1.6 times as tall as they're wide.
    private func isLimitedByHeight(_ size: CGSize) -> Bool {
        size.height > 0 && size.width <= size.height && size.width / size.height > 1 / 1.6
    }

    private func lineCanvas(_ layout: LinePageLayout?) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(
                    width: layout?.contentSize.width ?? 0,
                    height: layout?.contentSize.height ?? 0
                )

            if let layout {
                AyahScrollAnchorsView(wordFrames: wordFrames, layout: layout)

                #if QURAN_SYNC
                // Behind the line images, so underlines never cover Quran text.
                AyahReadingBookmarkUnderlines(
                    markers: markerPlacements(layout),
                    bookmarks: ayahReadingBookmarks,
                    pressedAyah: pressedReadingBookmarkAyah
                )
                #endif

                lineImages(layout)
                lineDividers(layout)

                sidelines(layout)
                suraHeaders(layout)
                highlights(layout)
                ayahMarkers(layout)
                ayahDim(layout)
            }
        }
        .frame(
            width: layout?.contentSize.width ?? 0,
            height: layout?.contentSize.height ?? 0,
            alignment: .topLeading
        )
        .allowsHitTesting(false)
        #if QURAN_SYNC
            .overlay {
                if let layout {
                    AyahReadingBookmarkTargets(
                        markers: markerPlacements(layout),
                        bookmarks: ayahReadingBookmarks,
                        pressedAyah: $pressedReadingBookmarkAyah,
                        onTap: onAyahReadingBookmarkTap
                    )
                }
            }
        #endif
            .environment(\.layoutDirection, .leftToRight)
            .onGlobalFrameChanged(onGlobalFrameChange)
    }

    #if QURAN_SYNC
    private func markerPlacements(_ layout: LinePageLayout) -> [AyahMarkerPlacement] {
        layout.ayahMarkerPlacements.map {
            AyahMarkerPlacement(ayah: $0.marker.ayah, frame: $0.frame)
        }
    }
    #endif

    @ViewBuilder
    private func sidelines(_ layout: LinePageLayout) -> some View {
        ForEach(layout.sidelinePlacements, id: \.sideline.id) { placement in
            if let image = imageForSideline(placement.sideline.id) {
                QuranThemedImage(image: image)
                    .placed(in: placement.frame)
            }
        }
    }

    @ViewBuilder
    private func suraHeaders(_ layout: LinePageLayout) -> some View {
        if drawsAyahNumbersAndSuraHeaders {
            ForEach(layout.suraHeaderPlacements, id: \.header.sura) { placement in
                SuraHeaderView(tint: chromePalette.header)
                    .placed(in: placement.frame)
            }
        }
    }

    /// Line pages have no word pointer, so every undimmed verse is highlighted and has highlight rects.
    @ViewBuilder
    private func ayahDim(_ layout: LinePageLayout) -> some View {
        if let undimmedVerses {
            QuranAyahDim(
                cutouts: layout.highlightRects
                    .filter { undimmedVerses.contains($0.ayah) }
                    .map(\.rect)
            )
        }
    }

    private func highlights(_ layout: LinePageLayout) -> some View {
        let rectsByVerse = Dictionary(grouping: layout.highlightRects, by: \.ayah)
        let verses = rectsByVerse.keys
            .filter { highlightColorsByVerse[$0] != nil }
            .sorted()
        return ForEach(verses, id: \.self) { verse in
            if let color = highlightColorsByVerse[verse], let rects = rectsByVerse[verse] {
                QuranHighlightShape(lineRects: rects.map(\.rect))
                    .fill(color)
            }
        }
    }

    @ViewBuilder
    private func ayahMarkers(_ layout: LinePageLayout) -> some View {
        if drawsAyahNumbersAndSuraHeaders {
            ForEach(layout.ayahMarkerPlacements, id: \.marker.ayah) { placement in
                AyahNumberView(number: placement.marker.ayah.ayah, palette: chromePalette)
                    .placed(in: placement.frame)
            }
        }
    }

    private func lineImages(_ layout: LinePageLayout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(layout.lineFrames.enumerated()), id: \.element.lineNumber) { item in
                let lineFrame = item.element
                let previousLineMaxY = item.offset == 0 ? 0 : layout.lineFrames[item.offset - 1].imageFrame.maxY
                let topPadding = lineFrame.imageFrame.minY - previousLineMaxY

                Group {
                    if let image = imageForLine(lineFrame.lineNumber) {
                        QuranThemedImage(image: image)
                    } else {
                        Color.clear
                    }
                }
                .frame(
                    width: lineFrame.imageFrame.width,
                    height: lineFrame.imageFrame.height,
                    alignment: .topLeading
                )
                .padding(.top, topPadding)
                .id(lineFrame.lineNumber)
            }
        }
        .padding(.leading, layout.pageFrame.minX)
        .frame(
            width: layout.contentSize.width,
            height: layout.contentSize.height,
            alignment: .topLeading
        )
    }

    private func lineDividers(_ layout: LinePageLayout) -> some View {
        ForEach(layout.lineDividers, id: \.lineNumber) { divider in
            // Drawn as ink, so dividers get the same theme tint as the line images.
            Color.black
                .invertThemedColorIfNeeded()
                .placed(in: hairlineFrame(for: divider.frame))
        }
    }

    /// One device pixel tall at the top of the divider frame, snapped to the pixel grid so it stays crisp.
    private func hairlineFrame(for frame: CGRect) -> CGRect {
        let scale = max(displayScale, 1)
        return CGRect(
            x: frame.minX,
            y: (frame.minY * scale).rounded() / scale,
            width: frame.width,
            height: 1 / scale
        )
    }
}
