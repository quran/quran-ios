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
import UIKit
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

    @Environment(\.colorScheme) private var colorScheme

    private var chromePalette: LinePageChromePalette {
        chromeStyle.palette(for: colorScheme)
    }

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
                lineDividers(layout)

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
                    SuraHeaderView(tint: chromePalette.header.foreground)
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
                    AyahNumberView(
                        number: placement.marker.ayah.ayah,
                        ringColor: chromePalette.marker.ringForeground,
                        fillColor: chromePalette.marker.content?.background,
                        textColor: chromePalette.marker.content?.foreground
                    )
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

    private func lineDividers(_ layout: LinePageLayout) -> some View {
        ForEach(layout.lineDividers, id: \.self) { divider in
            Color.primary
                .frame(width: divider.frame.width, height: divider.frame.height)
                .offset(x: divider.frame.minX, y: divider.frame.minY)
        }
    }
}

enum LinePageChromeStyle: Equatable {
    case greenChrome
    case blueChrome

    init(reading: Reading) {
        self = reading.usesBlueLinePageChrome ? .blueChrome : .greenChrome
    }
}

private struct LinePageChromeColors {
    let foreground: Color
    let background: Color?
}

private struct LinePageChromeMarkerPalette {
    let ringForeground: Color
    let content: LinePageChromeColors?
}

private struct LinePageChromePalette {
    let header: LinePageChromeColors
    let marker: LinePageChromeMarkerPalette
}

private func color(hex: Int) -> Color {
    Color(uiColor: UIColor(rgb: hex))
}

private extension LinePageChromeStyle {
    func palette(for colorScheme: ColorScheme) -> LinePageChromePalette {
        switch (self, colorScheme) {
        case (.blueChrome, .dark):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x73AFFA), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x73AFFA),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x73AFFA),
                        background: color(hex: 0x172554)
                    )
                )
            )
        case (.blueChrome, .light):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x2563EB), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x2563EB),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x1D4ED8),
                        background: color(hex: 0xEFF6FF)
                    )
                )
            )
        case (.greenChrome, .dark):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x047857), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x047857),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x34D399),
                        background: color(hex: 0x022C22)
                    )
                )
            )
        case (.greenChrome, .light):
            return LinePageChromePalette(
                header: LinePageChromeColors(foreground: color(hex: 0x047857), background: nil),
                marker: LinePageChromeMarkerPalette(
                    ringForeground: color(hex: 0x047857),
                    content: LinePageChromeColors(
                        foreground: color(hex: 0x047857),
                        background: color(hex: 0xECFDF5)
                    )
                )
            )
        @unknown default:
            return palette(for: .light)
        }
    }
}
