//
//  ContentLineView.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import ImageService
import NoorUI
import QuranGeometry
import QuranKit
import QuranPagesFeature
import SwiftUI
import UIx

struct ContentLineView: View {
    @StateObject var viewModel: ContentLineViewModel

    var body: some View {
        ContentLineViewBody(
            page: viewModel.page,
            layoutForSize: { viewModel.layout(for: $0, showHeaderFooter: false) },
            scrollToVerse: viewModel.scrollToVerse,
            wordFrames: viewModel.wordFrames,
            highlightColorsByVerse: viewModel.highlightColorsByVerse,
            chromeStyle: viewModel.chromeStyle,
            imageRenderingMode: viewModel.imageRenderingMode,
            imageForLine: viewModel.lineImage(for:),
            imageForSideline: viewModel.sidelineImage(for:),
            onGlobalFrameChange: viewModel.updateContentFrame
        )
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

struct ContentLineViewBody: View {
    // MARK: Internal

    let page: Page
    let layoutForSize: (CGSize) -> LinePageLayout?
    let scrollToVerse: AyahNumber?
    let wordFrames: WordFrameCollection
    let highlightColorsByVerse: [AyahNumber: Color]
    let chromeStyle: LinePageChromeStyle
    let imageRenderingMode: QuranThemedImage.RenderingMode
    let imageForLine: (Int) -> UIImage?
    let imageForSideline: (String) -> UIImage?
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
        .quranScrolling(scrollToValue: scrollToVerse, anchor: UnitPoint(x: 0, y: 0.2)) { ayah in
            wordFrames.wordFramesForVerse(ayah).first?.word
        }
    }

    // MARK: Private

    @ViewBuilder
    private func scrollAnchors(_ layout: LinePageLayout) -> some View {
        let verses = Set(wordFrames.lines.flatMap(\.frames).map(\.word.verse)).sorted()

        ForEach(verses, id: \.self) { ayah in
            if let anchorWord = wordFrames.wordFramesForVerse(ayah).first?.word,
               let start = layout.selectionAnchors(for: ayah)?.start
            {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: start.minY)

                    Color.clear
                        .frame(width: 1, height: 1)
                        .id(anchorWord)

                    Spacer(minLength: 0)
                }
                .frame(
                    width: layout.contentSize.width,
                    height: layout.contentSize.height,
                    alignment: .topLeading
                )
            }
        }
    }

    private func lineCanvas(_ layout: LinePageLayout?) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .frame(
                    width: layout?.contentSize.width ?? 0,
                    height: layout?.contentSize.height ?? 0
                )

            if let layout {
                scrollAnchors(layout)

                lineImages(layout)

                ForEach(layout.sidelinePlacements, id: \.self) { placement in
                    if let image = imageForSideline(placement.sideline.id) {
                        QuranThemedImage(image: image, renderingMode: imageRenderingMode)
                            .frame(
                                width: placement.frame.width,
                                height: placement.frame.height
                            )
                            .offset(
                                x: placement.frame.minX,
                                y: placement.frame.minY
                            )
                    }
                }

                ForEach(layout.suraHeaderPlacements, id: \.self) { placement in
                    LinePageSuraHeaderView(style: chromeStyle)
                        .frame(
                            width: placement.frame.width,
                            height: placement.frame.height
                        )
                        .offset(
                            x: placement.frame.minX,
                            y: placement.frame.minY
                        )
                }

                ForEach(layout.ayahMarkerPlacements, id: \.self) { placement in
                    LinePageAyahMarkerView(number: placement.marker.ayah.ayah, style: chromeStyle)
                        .frame(
                            width: placement.frame.width,
                            height: placement.frame.height
                        )
                        .offset(
                            x: placement.frame.minX,
                            y: placement.frame.minY
                        )
                }

                ForEach(layout.highlightRects, id: \.self) { highlight in
                    if let color = highlightColorsByVerse[highlight.ayah] {
                        color
                            .frame(
                                width: highlight.rect.width,
                                height: highlight.rect.height
                            )
                            .offset(
                                x: highlight.rect.minX,
                                y: highlight.rect.minY
                            )
                    }
                }
            }
        }
        .frame(
            width: layout?.contentSize.width ?? 0,
            height: layout?.contentSize.height ?? 0,
            alignment: .topLeading
        )
        .environment(\.layoutDirection, .leftToRight)
        .onGlobalFrameChanged(onGlobalFrameChange)
    }

    private func lineImages(_ layout: LinePageLayout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(layout.lineFrames.enumerated()), id: \.element) { item in
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
}

enum LinePageChromeStyle: Equatable {
    case greenChrome
    case blueChrome

    init(reading: Reading) {
        self = reading.usesBlueLinePageChrome ? .blueChrome : .greenChrome
    }
}

private struct LinePageChromePalette {
    let headerTint: Color
    let markerRing: Color
    let markerInner: Color
    let markerText: Color
}

private func rgb(_ hex: Int) -> Color {
    Color(
        red: Double((hex >> 16) & 0xFF) / 255,
        green: Double((hex >> 8) & 0xFF) / 255,
        blue: Double(hex & 0xFF) / 255
    )
}

private extension LinePageChromeStyle {
    func palette(for colorScheme: ColorScheme) -> LinePageChromePalette {
        switch (self, colorScheme) {
        case (.blueChrome, .dark):
            return LinePageChromePalette(
                headerTint: rgb(0x73AFFA),
                markerRing: rgb(0x73AFFA),
                markerInner: rgb(0x172554),
                markerText: rgb(0x73AFFA)
            )
        case (.blueChrome, .light):
            return LinePageChromePalette(
                headerTint: rgb(0x2563EB),
                markerRing: rgb(0x2563EB),
                markerInner: rgb(0xEFF6FF),
                markerText: rgb(0x1D4ED8)
            )
        case (.greenChrome, .dark):
            return LinePageChromePalette(
                headerTint: rgb(0x047857),
                markerRing: rgb(0x047857),
                markerInner: rgb(0x022C22),
                markerText: rgb(0x34D399)
            )
        case (.greenChrome, .light):
            return LinePageChromePalette(
                headerTint: rgb(0x047857),
                markerRing: rgb(0x047857),
                markerInner: rgb(0xECFDF5),
                markerText: rgb(0x047857)
            )
        @unknown default:
            return palette(for: .light)
        }
    }
}

private struct LinePageSuraHeaderView: View {
    let style: LinePageChromeStyle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if style == .greenChrome {
            NoorImage.suraHeader.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.pageMarkerTint)
                .themedColorScheme()
        } else {
            let palette = style.palette(for: colorScheme)
            NoorImage.suraHeader.image
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(palette.headerTint)
                .themedColorScheme()
        }
    }
}

private struct LinePageAyahMarkerView: View {
    let number: Int
    let style: LinePageChromeStyle
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if style == .greenChrome {
            NoorImage.ayahEnd.image
                .renderingMode(.template)
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
                .themedColorScheme()
        } else {
            let palette = style.palette(for: colorScheme)

            ZStack {
                Circle()
                    .fill(palette.markerInner)
                    .padding(5)

                NoorImage.ayahEnd.image
                    .renderingMode(.template)
                    .resizable()
                    .padding(.horizontal, 1)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(palette.markerRing)

                Text(NumberFormatter.arabicNumberFormatter.format(number))
                    .font(.largeTitle)
                    .minimumScaleFactor(0.03)
                    .padding(3)
                    .foregroundColor(palette.markerText)
            }
            .themedColorScheme()
        }
    }
}
