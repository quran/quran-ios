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
    let onAnnotatedAyahTap: (AyahNumber, CGPoint) -> Void
    #endif

    var body: some View {
        #if QURAN_SYNC
        let content = ContentLineViewBody(
            page: viewModel.page,
            layoutForSize: { viewModel.layout(for: $0, showHeaderFooter: false) },
            scrollToVerse: viewModel.scrollToVerse,
            wordFrames: viewModel.wordFrames,
            highlightColorsByVerse: viewModel.highlightColorsByVerse,
            ayahAnnotations: viewModel.ayahAnnotations,
            drawsAyahNumbersAndSuraHeaders: viewModel.drawsAyahNumbersAndSuraHeaders,
            chromeStyle: viewModel.chromeStyle,
            imageRenderingMode: viewModel.imageRenderingMode,
            imageForLine: viewModel.lineImage(for:),
            imageForSideline: viewModel.sidelineImage(for:),
            onAnnotatedAyahTap: onAnnotatedAyahTap,
            onGlobalFrameChange: viewModel.updateContentFrame
        )
        #else
        let content = ContentLineViewBody(
            page: viewModel.page,
            layoutForSize: { viewModel.layout(for: $0, showHeaderFooter: false) },
            scrollToVerse: viewModel.scrollToVerse,
            wordFrames: viewModel.wordFrames,
            highlightColorsByVerse: viewModel.highlightColorsByVerse,
            drawsAyahNumbersAndSuraHeaders: viewModel.drawsAyahNumbersAndSuraHeaders,
            chromeStyle: viewModel.chromeStyle,
            imageRenderingMode: viewModel.imageRenderingMode,
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
            .task {
                await viewModel.loadLinePage()
            }
    }
}

private struct ContentLineViewBody: View {
    // MARK: Internal

    let page: Page
    let layoutForSize: (CGSize) -> LinePageLayout?
    let scrollToVerse: AyahNumber?
    let wordFrames: WordFrameCollection
    let highlightColorsByVerse: [AyahNumber: Color]
    #if QURAN_SYNC
    let ayahAnnotations: [AyahNumber: Set<AyahAnnotation>]
    #endif
    let drawsAyahNumbersAndSuraHeaders: Bool
    let chromeStyle: LinePageChromeStyle
    let imageRenderingMode: QuranThemedImage.RenderingMode
    let imageForLine: (Int) -> UIImage?
    let imageForSideline: (String) -> UIImage?
    #if QURAN_SYNC
    let onAnnotatedAyahTap: (AyahNumber, CGPoint) -> Void
    #endif
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        AdaptiveQuranScrollView {
            QuranPageHeader(
                quarterName: page.localizedQuarterName,
                suraNames: page.suraNames()
            )
        } footer: {
            QuranPageFooter(page: page.localizedNumber)
        } content: { availableContentSize in
            lineCanvas(layoutForSize(availableContentSize))
        }
        .font(.footnote)
        .populateReadableInsets()
        .themedBackground()
        .quranScrolling(scrollToValue: scrollToVerse) { AyahScrollTarget(ayah: $0) }
    }

    // MARK: Private

    @Environment(\.colorScheme) private var colorScheme

    private var chromePalette: LinePageChromePalette {
        chromeStyle.palette(for: colorScheme)
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

                lineImages(layout)
                lineDividers(layout)

                sidelines(layout)
                suraHeaders(layout)
                highlights(layout)
                ayahMarkers(layout)
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
                    AyahAnnotationsView(
                        markers: layout.ayahMarkerPlacements.map {
                            AyahMarkerPlacement(ayah: $0.marker.ayah, frame: $0.frame)
                        },
                        annotations: ayahAnnotations,
                        onAnnotatedAyahTap: onAnnotatedAyahTap
                    )
                }
            }
        #endif
            .environment(\.layoutDirection, .leftToRight)
            .onGlobalFrameChanged(onGlobalFrameChange)
    }

    @ViewBuilder
    private func sidelines(_ layout: LinePageLayout) -> some View {
        ForEach(layout.sidelinePlacements, id: \.sideline.id) { placement in
            if let image = imageForSideline(placement.sideline.id) {
                QuranThemedImage(image: image, renderingMode: imageRenderingMode)
                    .placed(in: placement.frame)
            }
        }
    }

    @ViewBuilder
    private func suraHeaders(_ layout: LinePageLayout) -> some View {
        if drawsAyahNumbersAndSuraHeaders {
            ForEach(layout.suraHeaderPlacements, id: \.header.sura) { placement in
                SuraHeaderView(tint: chromePalette.header.foreground)
                    .placed(in: placement.frame)
            }
        }
    }

    @ViewBuilder
    private func highlights(_ layout: LinePageLayout) -> some View {
        ForEach(layout.highlightRects, id: \.self) { highlight in
            if let color = highlightColorsByVerse[highlight.ayah] {
                color
                    .placed(in: highlight.rect)
            }
        }
    }

    @ViewBuilder
    private func ayahMarkers(_ layout: LinePageLayout) -> some View {
        if drawsAyahNumbersAndSuraHeaders {
            ForEach(layout.ayahMarkerPlacements, id: \.marker.ayah) { placement in
                AyahNumberView(
                    number: placement.marker.ayah.ayah,
                    ringColor: chromePalette.marker.ringForeground,
                    fillColor: chromePalette.marker.content?.background,
                    textColor: chromePalette.marker.content?.foreground
                )
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
                        QuranThemedImage(image: image, renderingMode: imageRenderingMode)
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
            Color.primary
                .placed(in: divider.frame)
        }
    }
}
