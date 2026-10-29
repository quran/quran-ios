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
    let onAyahIndicatorTap: (AyahNumber, CGPoint) -> Void
    #endif

    var body: some View {
        VStack {
            #if QURAN_SYNC
            ContentImageViewBody(
                decorations: viewModel.decorations,
                ayahReadingBookmarks: viewModel.ayahReadingBookmarks,
                pageReadingBookmarks: viewModel.pageReadingBookmarks,
                onAyahIndicatorTap: onAyahIndicatorTap,
                image: viewModel.imagePage?.image,
                renderingMode: viewModel.imageRenderingMode,
                page: viewModel.page,
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
                page: viewModel.page,
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
    var ayahReadingBookmarks: [AyahNumber: [ReadingBookmarkSlot]] = [:]
    var pageReadingBookmarks: [ReadingBookmarkSlot] = []
    var onAyahIndicatorTap: (AyahNumber, CGPoint) -> Void = { _, _ in }
    #endif
    let image: UIImage?
    let renderingMode: QuranThemedImage.RenderingMode
    let page: Page
    let scrollToVerse: AyahNumber?
    let wordFrames: WordFrameCollection?
    let onScaleChange: (WordFrameScale) -> Void
    let onGlobalFrameChange: (CGRect) -> Void

    var body: some View {
        #if QURAN_SYNC
        let content = AdaptiveImageScrollView(
            decorations: decorations,
            renderingMode: renderingMode,
            ayahReadingBookmarks: ayahReadingBookmarks
        ) {
            image
        } onAyahIndicatorTap: {
            onAyahIndicatorTap($0, $1)
        } onScaleChange: {
            onScaleChange($0)
        } onGlobalFrameChange: {
            onGlobalFrameChange($0)
        } header: {
            header
        } footer: {
            QuranPageFooter(page: page.localizedNumber)
        }
        #else
        let content = AdaptiveImageScrollView(decorations: decorations, renderingMode: renderingMode) {
            image
        } onScaleChange: {
            onScaleChange($0)
        } onGlobalFrameChange: {
            onGlobalFrameChange($0)
        } header: {
            header
        } footer: {
            QuranPageFooter(page: page.localizedNumber)
        }
        #endif
        return content
            .font(.footnote)
            .populateReadableInsets()
            .quranScrolling(scrollToValue: scrollToVerse) { AyahScrollTarget(ayah: $0) }
    }

    private var header: some View {
        QuranPageHeader(quarterName: page.localizedQuarterName, suras: page.suras)
        #if QURAN_SYNC
            .pageReadingBookmarkRibbons(page: page, slots: pageReadingBookmarks)
        #endif
    }
}

#Preview {
    let decorations = ImageDecorations(
        suraHeaders: [],
        ayahNumbers: [],
        drawsAyahNumbersAndSuraHeaders: false,
        wordFrames: WordFrameCollection(frames: [])
    )

    ContentImageViewBody(
        decorations: decorations,
        image: UIImage(contentsOfFile: testResourceURL("images/page604.png").path)!,
        renderingMode: .tinted,
        page: Quran.hafsMadani1405.pages[603],
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
