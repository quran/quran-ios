//
//  ContentLineView.swift
//
//
//  Created by Mohamed Afifi on 2026-03-29.
//

import ImageService
import NoorUI
import QuranKit
import QuranPagesFeature
import SwiftUI
import UIx

struct ContentLineView: View {
    @StateObject var viewModel: ContentLineViewModel
    @State private var windowSafeAreaInsets: EdgeInsets = .zero

    var body: some View {
        GeometryReader { geometry in
            let horizontalGutter = max(windowSafeAreaInsets.leading, windowSafeAreaInsets.trailing)
            let layoutSize = CGSize(
                width: max(0, geometry.size.width - (2 * horizontalGutter)),
                height: geometry.size.height
            )
            let layout = viewModel.layout(for: layoutSize)
            ContentLineViewBody(
                page: viewModel.page,
                layout: layout,
                horizontalGutter: horizontalGutter,
                scrollToVerse: viewModel.scrollToVerse,
                highlightColorsByVerse: viewModel.highlightColorsByVerse,
                chromeStyle: viewModel.chromeStyle,
                imageRenderingMode: viewModel.imageRenderingMode,
                imageForLine: viewModel.lineImage(for:),
                imageForSideline: viewModel.sidelineImage(for:),
                onGlobalFrameChange: viewModel.updateContentFrame
            )
        }
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
        .readWindowSafeAreaInsets($windowSafeAreaInsets)
    }
}

struct ContentLineViewBody: View {
    // MARK: Internal

    let page: Page
    let layout: LinePageLayout?
    let horizontalGutter: CGFloat
    let scrollToVerse: AyahNumber?
    let highlightColorsByVerse: [AyahNumber: Color]
    let chromeStyle: LinePageChromeStyle
    let imageRenderingMode: QuranThemedImage.RenderingMode
    let imageForLine: (Int) -> UIImage?
    let imageForSideline: (String) -> UIImage?
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        scrollView {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(
                        width: layout?.contentSize.width ?? 0,
                        height: layout?.contentSize.height ?? 0
                    )

                if let layout {
                    lineScrollAnchors(layout)

                    ForEach(layout.lineFrames, id: \.self) { lineFrame in
                        if let image = imageForLine(lineFrame.lineNumber) {
                            QuranThemedImage(image: image, renderingMode: imageRenderingMode)
                                .frame(
                                    width: lineFrame.imageFrame.width,
                                    height: lineFrame.imageFrame.height
                                )
                                .offset(
                                    x: lineFrame.imageFrame.minX,
                                    y: lineFrame.imageFrame.minY
                                )
                        }
                    }

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

                    if layout.headerFrame.height > 0 {
                        QuranPageHeader(
                            quarterName: page.localizedQuarterName,
                            suraNames: page.suraNames(),
                            readableInsetEdges: []
                        )
                        .frame(
                            width: layout.headerFrame.width,
                            height: layout.headerFrame.height,
                            alignment: .topLeading
                        )
                        .offset(
                            x: layout.headerFrame.minX,
                            y: layout.headerFrame.minY
                        )
                        .environment(\.layoutDirection, layoutDirection)
                        .zIndex(1)
                    }

                    if layout.footerFrame.height > 0 {
                        QuranPageFooter(page: page.localizedNumber, readableInsetEdges: [])
                            .frame(
                                width: layout.footerFrame.width,
                                height: layout.footerFrame.height,
                                alignment: .topLeading
                            )
                            .offset(
                                x: layout.footerFrame.minX,
                                y: layout.footerFrame.minY
                            )
                            .environment(\.layoutDirection, layoutDirection)
                            .zIndex(1)
                    }
                }
            }
            .frame(
                width: layout?.contentSize.width ?? 0,
                height: layout?.contentSize.height ?? 0,
                alignment: .topLeading
            )
            .padding(.horizontal, horizontalGutter)
            .environment(\.layoutDirection, .leftToRight)
            .onGlobalFrameChanged(onGlobalFrameChange)
        }
        .font(.footnote)
        .themedBackground()
        .quranScrolling(scrollToValue: scrollToVerse) { ayah in
            layout?.scrollTargetLineNumber(for: ayah)
        }
    }

    // MARK: Private

    @Environment(\.layoutDirection) private var layoutDirection

    @ViewBuilder
    private func scrollView(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 16.4, *) {
            ScrollView(content: content)
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView(content: content)
        }
    }

    private func lineScrollAnchors(_ layout: LinePageLayout) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(layout.lineFrames.enumerated()), id: \.element) { item in
                let lineFrame = item.element
                let anchorY = lineFrame.imageFrame.minY
                let previousAnchorMaxY = item.offset == 0 ? 0 : (layout.lineFrames[item.offset - 1].imageFrame.minY + 1)
                let topPadding = max(0, anchorY - previousAnchorMaxY)

                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)
                    .padding(.top, topPadding)
                    .id(lineFrame.lineNumber)
            }
        }
        .frame(width: layout.contentSize.width, height: layout.contentSize.height, alignment: .topLeading)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum LinePageChromeStyle: Equatable {
    case classic
    case newMadani

    init(reading: Reading) {
        // Keep all current iOS line-page readings on the existing green styling.
        // Future 1439-style line pages can opt into `.newMadani`.
        self = .classic
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
        case (.newMadani, .dark):
            return LinePageChromePalette(
                headerTint: rgb(0x73AFFA),
                markerRing: rgb(0x73AFFA),
                markerInner: rgb(0x172554),
                markerText: rgb(0x73AFFA)
            )
        case (.newMadani, .light):
            return LinePageChromePalette(
                headerTint: rgb(0x2563EB),
                markerRing: rgb(0x2563EB),
                markerInner: rgb(0xEFF6FF),
                markerText: rgb(0x1D4ED8)
            )
        case (.classic, .dark):
            return LinePageChromePalette(
                headerTint: rgb(0x047857),
                markerRing: rgb(0x047857),
                markerInner: rgb(0x022C22),
                markerText: rgb(0x34D399)
            )
        case (.classic, .light):
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
        if style == .classic {
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
        if style == .classic {
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
