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

    var body: some View {
        ContentTranslationView(viewModel: viewModel.translationViewModel)
    }
}
