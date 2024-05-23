//
//  ContentImageView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import NoorUI
import QuranGeometry
import SwiftUI

struct ContentImageView: View {
    @ObservedObject var viewModel: ContentImageViewModel

    var body: some View {
        VStack {
            ContentImageViewBody(
                decorations: viewModel.decorations,
                image: viewModel.imagePage?.image,
                quarterName: viewModel.page.localizedQuarterName,
                suraNames: viewModel.page.suraNames(),
                page: viewModel.page.localizedNumber,
                scrollToItem: viewModel.scrollToItem,
                onScaleChange: { viewModel.scale = $0 },
                onGlobalFrameChange: { viewModel.imageFrame = $0 }
            )
        }
        .task {
            await viewModel.loadImagePage()
        }
    }
}

private struct ContentImageViewBody: View {
    let decorations: ImageDecorations
    let image: UIImage?
    let quarterName: String
    let suraNames: MultipartText
    let page: String
    let scrollToItem: WordFrameLine?
    let onScaleChange: (WordFrameScale) -> Void
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        ScrollViewReader { scrollView in
            AdaptiveImageScrollView(decorations: decorations) {
                image
            } onScaleChange: {
                onScaleChange($0)
            } onGlobalFrameChange: {
                onGlobalFrameChange($0)
            } header: {
                QuranPageHeader(quarterName: quarterName, suraNames: suraNames)
            } footer: {
                QuranPageFooter(page: page)
            }
            // TODO: Should be part of the headers and footers.
            .font(.footnote)
            .populateReadableInsets()
            .onChange(of: scrollToItem) { scrollToItem in
                if let scrollToItem {
                    withAnimation {
                        scrollView.scrollTo(scrollToItem, anchor: UnitPoint(x: 0, y: 0.2))
                    }
                }
            }
        }
    }
}

#Preview {
    ContentImageViewBody(
        decorations: ImageDecorations(
            suraHeaders: [],
            ayahNumbers: [],
            wordFrames: WordFrameCollection(lines: []),
            highlights: [:]
        ),
        image: UIImage(contentsOfFile: testResourceURL("images/page604.png").absoluteString)!,
        quarterName: "ABC",
        suraNames: "ABC",
        page: "604",
        scrollToItem: nil,
        onScaleChange: { _ in },
        onGlobalFrameChange: { _ in }
    )
    .populateReadableInsets()
    .ignoresSafeArea()
}
