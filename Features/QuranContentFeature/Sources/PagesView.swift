//
//  PagesView.swift
//
//
//  Created by Mohamed Afifi on 2024-10-06.
//

import QuranPagesFeature
import QuranTextKit
import SwiftUI
import UIx

struct PagesView: View {
    @StateObject var viewModel: ContentViewModel

    var body: some View {
        GeometryReader { geometry in
            QuranPaginationView(
                pagingStrategy: pagingStrategy(with: geometry),
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
            }
            .id(viewModel.quranMode)
        }
        // Measure without the keyboard. A keyboard, even one shown by a presented editor,
        // would make portrait look landscape and flip the reader to double pages.
        .ignoresSafeArea(.keyboard)
        .collectGeometryActions($viewModel.geometryActions)
    }

    private func pagingStrategy(with geometry: GeometryProxy) -> PagingStrategy {
        // If portrait
        if geometry.size.height > geometry.size.width {
            return .singlePage
        }

        if !TwoPagesUtils.hasEnoughHorizontalSpace() {
            return .singlePage
        }

        return viewModel.pagingStrategy
    }
}
