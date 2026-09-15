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

    private let onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?

    public init(viewModel: @autoclosure @escaping () -> ContentTranslationViewModel, onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel())
        self.onAyahNumberTapped = onAyahNumberTapped
    }

    public var body: some View {
        ContentTranslationViewBody(
            items: viewModel.items(quranFont: viewModel.reading.quranFont),
            arabicFontSize: viewModel.arabicFontSize,
            translationFontSize: viewModel.translationFontSize,
            highlights: viewModel.highlights,
            scrollToItem: viewModel.scrollToItem,
            tracker: viewModel.tracker,
            footnote: $viewModel.footnote,
            openURL: { viewModel.openURL($0) },
            onAyahNumberTapped: onAyahNumberTapped
        )
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
    let items: [TranslationItem]

    let arabicFontSize: FontSize
    let translationFontSize: FontSize
    let highlights: [AyahNumber: Color]
    let scrollToItem: TranslationItemId?
    let tracker: CollectionTracker<TranslationItemId>

    @Binding var footnote: TranslationFootnote?

    let openURL: (TranslationURL) -> Void
    let onAyahNumberTapped: ((AyahNumber, CGPoint) -> Void)?

    var body: some View {
        List {
            ForEach(items) { item in
                item.view(onAyahNumberTapped: onAyahNumberTapped)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 1)
        .populateReadableInsets()
        .openTranslationURL(openURL)
        .trackCollection(with: tracker)
        .sheet(item: $footnote) { $0 }
        .quranScrolling(scrollToValue: scrollToItem) { item in
            items.contains { $0.id == item } ? item : nil
        }
    }
}
