//
//  PagesView.swift
//
//
//  Created by Mohamed Afifi on 2024-10-06.
//

import QuranPagesFeature
import SwiftUI
import UIx

struct PagesView: View {
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        GeometryReader { geometry in
            let strategy = pagingStrategy(with: geometry)
            QuranPaginationView(
                pagingStrategy: strategy,
                selection: $viewModel.visiblePages,
                pages: viewModel.deps.quran.pages,
                onVisiblePageChanged: viewModel.onVisiblePageChanged
            ) { page in
                Group {
                    switch viewModel.quranMode {
                    case .arabic:
                        #if QURAN_SYNC
                        viewModel.deps.imageDataSourceBuilder.build(at: page) {
                            viewModel.onAyahNumberTapped($0, at: $1)
                        } onPageReadingBookmarkTap: {
                            viewModel.onPageReadingBookmarkTapped(page, at: $0)
                        }
                        #else
                        viewModel.deps.imageDataSourceBuilder.build(at: page)
                        #endif
                    case .translation:
                        #if QURAN_SYNC
                        viewModel.deps.translationDataSourceBuilder.build(at: page) {
                            viewModel.onAyahNumberTapped($0, at: $1)
                        }
                        #else
                        viewModel.deps.translationDataSourceBuilder.build(at: page)
                        #endif
                    }
                }
                .onAppear { viewModel.onPageContentAppear(pagingStrategy: strategy) }
            }
            .id(viewModel.quranMode)
        }
        // Measure without the keyboard. A keyboard, even one shown by a presented editor,
        // would make portrait look landscape and flip the reader to double pages.
        .ignoresSafeArea(.keyboard)
        .collectGeometryActions($viewModel.geometryActions)
    }

    private func pagingStrategy(with geometry: GeometryProxy) -> PagingStrategy {
        // The reader fills its window, so its size plus its safe areas is the window's size.
        // Folding or unfolding iPhone Duo resizes the window, so never use the screen's size.
        let insets = geometry.safeAreaInsets
        let windowSize = CGSize(
            width: geometry.size.width + insets.leading + insets.trailing,
            height: geometry.size.height + insets.top + insets.bottom
        )
        return viewModel.pagingStrategy(windowSize: windowSize)
    }
}
