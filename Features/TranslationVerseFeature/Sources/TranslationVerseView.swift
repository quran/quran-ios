//
//  TranslationVerseView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-01.
//

import Combine
import NoorUI
import QuranKit
import QuranTranslationFeature
import SwiftUI

struct TranslationVerseView: View {
    // MARK: Lifecycle

    init(viewModel: TranslationVerseViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        pages = viewModel.verses.map(VersePage.init)
    }

    // MARK: Internal

    var body: some View {
        PageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            interPageSpacing: ContentDimension.interPageSpacing,
            animated: true,
            selection: selection
        ) {
            ForEach(pages) { page in
                content(for: page.verse)
                    .environment(\.layoutDirection, layoutDirection)
            }
        }
        // Page through verses in Quran reading order, like the reader.
        .environment(\.layoutDirection, .rightToLeft)
        .themedBackground()
        .themedForeground()
        .populateThemeStyle()
        .background(TranslationVerseToasts(viewModel: viewModel))
        .enableToastPresenter()
    }

    // MARK: Private

    private struct VersePage: Identifiable, Equatable {
        let verse: AyahNumber

        var id: AyahNumber { verse }
    }

    @StateObject private var viewModel: TranslationVerseViewModel
    @Environment(\.layoutDirection) private var layoutDirection

    private let pages: [VersePage]

    private var selection: Binding<VersePage> {
        Binding(
            get: { VersePage(verse: viewModel.currentVerse) },
            set: { viewModel.currentVerse = $0.verse }
        )
    }

    @ViewBuilder
    private func content(for verse: AyahNumber) -> some View {
        #if QURAN_SYNC
        // This standalone verse sheet has no ayah-menu presentation.
        ContentTranslationView(viewModel: viewModel.translationViewModel(for: verse), onAyahNumberTapped: nil)
        #else
        ContentTranslationView(viewModel: viewModel.translationViewModel(for: verse))
        #endif
    }
}

/// Shows the view model's toasts, like the way back from a footnote's verse reference.
private struct TranslationVerseToasts: View {
    let viewModel: TranslationVerseViewModel
    @Environment(\.showToast) private var showToast

    var body: some View {
        Color.clear
            .onReceive(viewModel.$toast.compactMap { $0 }) { toast in
                viewModel.toast = nil
                showToast?(toast)
            }
    }
}
