//
//  ContentImageView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-10.
//

import NoorUI
import QuranAnnotations
import QuranGeometry
import QuranKit
import QuranLocalization
import QuranPagesFeature
import SwiftUI

struct ContentImageView: View {
    @StateObject var viewModel: ContentImageViewModel
    #if QURAN_SYNC
    let onAnnotatedAyahTap: (AyahNumber, CGPoint) -> Void
    #endif

    var body: some View {
        VStack {
            #if QURAN_SYNC
            ContentImageViewBody(
                decorations: viewModel.decorations,
                ayahAnnotations: viewModel.ayahAnnotations,
                onAnnotatedAyahTap: onAnnotatedAyahTap,
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
            #else
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
            #endif
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

private struct ContentImageViewBody: View {
    let decorations: ImageDecorations
    #if QURAN_SYNC
    var ayahAnnotations: [AyahNumber: Set<AyahAnnotation>] = [:]
    var onAnnotatedAyahTap: (AyahNumber, CGPoint) -> Void = { _, _ in }
    #endif
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
        #if QURAN_SYNC
        let content = AdaptiveImageScrollView(
            decorations: decorations,
            renderingMode: renderingMode,
            ayahAnnotations: ayahAnnotations,
            onAnnotatedAyahTap: onAnnotatedAyahTap
        ) {
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
        #else
        let content = AdaptiveImageScrollView(decorations: decorations, renderingMode: renderingMode) {
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
        #endif
        return content
            .font(.footnote)
            .populateReadableInsets()
            .quranScrolling(scrollToValue: scrollToVerse) { AyahScrollTarget(ayah: $0) }
    }
}

#Preview {
    let decorations = ImageDecorations(
        suraHeaders: [],
        ayahNumbers: [],
        drawsAyahNumbersAndSuraHeaders: false,
        wordFrames: WordFrameCollection(frames: []),
        highlights: [:]
    )

    ContentImageViewBody(
        decorations: decorations,
        image: UIImage(contentsOfFile: testResourceURL("images/page604.png").path)!,
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
