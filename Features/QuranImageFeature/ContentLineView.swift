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

struct ContentLineView: View {
    @StateObject var viewModel: ContentLineViewModel

    var body: some View {
        GeometryReader { geometry in
            ContentLineViewBody(
                page: viewModel.page,
                layout: viewModel.layout(for: geometry.size),
                imageRenderingMode: viewModel.imageRenderingMode,
                imageForLine: viewModel.lineImage(for:)
            )
        }
        .task {
            await viewModel.loadLinePage()
        }
    }
}

private struct ContentLineViewBody: View {
    // MARK: Internal

    let page: Page
    let layout: LinePageLayout?
    let imageRenderingMode: QuranThemedImage.RenderingMode
    let imageForLine: (Int) -> UIImage?

    var body: some View {
        scrollView {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(
                        width: layout?.contentSize.width ?? 0,
                        height: layout?.contentSize.height ?? 0
                    )

                if let layout {
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
                            .zIndex(1)
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topLeading
            )
        }
        .font(.footnote)
        .populateReadableInsets()
        .themedBackground()
    }

    // MARK: Private

    @ViewBuilder
    private func scrollView(@ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 16.4, *) {
            ScrollView(content: content)
                .scrollBounceBehavior(.basedOnSize)
        } else {
            ScrollView(content: content)
        }
    }
}
