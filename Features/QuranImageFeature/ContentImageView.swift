//
//  ContentImageView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import NoorUI
import QuranGeometry
import QuranKit
import QuranPagesFeature
import SwiftUI

struct ContentImageView: View {
    @StateObject var viewModel: ContentImageViewModel

    var body: some View {
        VStack {
            ContentImageViewBody(
                decorations: viewModel.decorations,
                image: viewModel.imagePage?.image,
                renderingMode: viewModel.imageRenderingMode,
                quarterName: viewModel.page.localizedQuarterName,
                suraNames: viewModel.page.suraNames(),
                page: viewModel.page.localizedNumber,
                scrollToVerse: viewModel.scrollToVerse,
                wordFrames: viewModel.imagePage?.wordFrames,
                onScaleChange: { viewModel.scale = $0 },
                onGlobalFrameChange: { viewModel.imageFrame = $0 }
            )
        }
        .geometryActions(
            PageGeometryActions(
                id: ObjectIdentifier(viewModel),
                word: { point in viewModel.wordAtGlobalPoint(point) },
                verse: { point in viewModel.wordAtGlobalPoint(point)?.verse }
            )
        )
        .task {
            await viewModel.loadImagePage()
        }
    }
}

struct ContentImageViewBody: View {
    let decorations: ImageDecorations
    let image: UIImage?
    let renderingMode: QuranThemedImage.RenderingMode
    let quarterName: String
    let suraNames: MultipartText
    let page: String
    let scrollToVerse: AyahNumber?
    let wordFrames: WordFrameCollection?
    let onScaleChange: (WordFrameScale) -> Void
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        AdaptiveImageScrollView(decorations: decorations, renderingMode: renderingMode) {
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
        .font(.footnote)
        .populateReadableInsets()
        .quranScrolling(scrollToValue: scrollToVerse) {
            wordFrames?.lineFramesVerVerse($0).first
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
        renderingMode: .tinted,
        quarterName: "ABC",
        suraNames: "ABC",
        page: "604",
        scrollToVerse: nil,
        wordFrames: nil,
        onScaleChange: { _ in },
        onGlobalFrameChange: { _ in }
    )
    .themedBackground()
    .populateReadableInsets()
    .ignoresSafeArea()
    .environment(\.themeStyle, .calm)
}
