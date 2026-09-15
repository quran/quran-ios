//
//  TranslationVerseView.swift
//
//
//  Created by Mohamed Afifi on 2024-02-01.
//

import QuranTranslationFeature
import SwiftUI

struct TranslationVerseView: View {
    @StateObject var viewModel: TranslationVerseViewModel

    @ViewBuilder
    private var content: some View {
        #if QURAN_SYNC
        // This standalone verse sheet has no ayah-menu presentation.
        ContentTranslationView(viewModel: viewModel.translationViewModel, onAyahNumberTapped: { _, _ in })
        #else
        ContentTranslationView(viewModel: viewModel.translationViewModel)
        #endif
    }

    var body: some View {
        content
            .themedBackground()
            .themedForeground()
            .populateThemeStyle()
    }
}
