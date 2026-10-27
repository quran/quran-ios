//
//  ContentTranslationView.swift
//
//
//  Created by Mohamed Afifi on 2023-12-29.
//

import NoorUI
import QuranKit
import QuranPagesFeature
import QuranText
import SwiftUI
import UIx
import Utilities

public struct ContentTranslationView: View {
    @StateObject var viewModel: ContentTranslationViewModel

    #if QURAN_SYNC
    private let onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?

    /// A `nil` `onAyahNumberTapped` shows the verse numbers without making them tappable.
    public init(viewModel: @autoclosure @escaping () -> ContentTranslationViewModel, onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onAyahNumberTapped = onAyahNumberTapped
    }
    #else
    public init(viewModel: @autoclosure @escaping () -> ContentTranslationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }
    #endif

    @ViewBuilder
    private var content: some View {
        #if QURAN_SYNC
        ContentTranslationViewBody(
            section: viewModel.pageSection(quranFont: viewModel.reading.quranFont),
            arabicFontSize: viewModel.arabicFontSize,
            translationFontSize: viewModel.translationFontSize,
            highlights: viewModel.highlights,
            scrollToItem: viewModel.scrollToItem,
            tracker: viewModel.tracker,
            footnote: $viewModel.footnote,
            openURL: { viewModel.openURL($0) },
            onAyahNumberTapped: onAyahNumberTapped
        )
        #else
        ContentTranslationViewBody(
            section: viewModel.pageSection(quranFont: viewModel.reading.quranFont),
            arabicFontSize: viewModel.arabicFontSize,
            translationFontSize: viewModel.translationFontSize,
            highlights: viewModel.highlights,
            scrollToItem: viewModel.scrollToItem,
            tracker: viewModel.tracker,
            footnote: $viewModel.footnote,
            openURL: { viewModel.openURL($0) }
        )
        #endif
    }

    public var body: some View {
        content
            .geometryActions(
                PageGeometryActions(
                    id: ObjectIdentifier(viewModel),
                    word: { _ in nil },
                    verse: { point in viewModel.ayahAtPoint(point) }
                )
            )
            .task(id: Pair(viewModel.verses, viewModel.selectedTranslations)) {
                await viewModel.load()
            }
    }
}

private struct ContentTranslationViewBody: View {
    let section: TranslationPageSection?

    let arabicFontSize: FontSize
    let translationFontSize: FontSize
    let highlights: [AyahNumber: Color]
    let scrollToItem: TranslationItemId?
    let tracker: CollectionTracker<TranslationItemId>

    @Binding var footnote: TranslationFootnote?

    let openURL: (TranslationURL) -> Void
    #if QURAN_SYNC
    let onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?
    #endif

    var body: some View {
        List {
            if let section {
                #if QURAN_SYNC
                TranslationPageRows(section: section, onAyahNumberTapped: onAyahNumberTapped)
                #else
                TranslationPageRows(section: section)
                #endif
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
        .populateReadableInsets()
        .openTranslationURL(openURL)
        .trackCollection(with: tracker)
        .sheet(item: $footnote) { $0 }
        .quranScrolling(scrollToValue: scrollToItem) { item in
            section?.scrollTarget(for: item)
        }
    }
}

private struct TranslationPageRows: View {
    let section: TranslationPageSection
    #if QURAN_SYNC
    let onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?
    #endif

    var body: some View {
        ForEach(section.items) { item in
            #if QURAN_SYNC
            item.view(onAyahNumberTapped: onAyahNumberTapped)
            #else
            item.view()
            #endif
        }
    }
}
