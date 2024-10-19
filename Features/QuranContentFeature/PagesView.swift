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
                pages: viewModel.deps.quran.pages
            ) { page in
                Group {
                    switch viewModel.quranMode {
                    case .arabic:
                        viewModel.deps.imageDataSourceBuilder.build(at: page)
                    case .translation:
                        viewModel.deps.translationDataSourceBuilder.build(at: page)
                    }
                }
            }
            .id(viewModel.quranMode)
        }
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
