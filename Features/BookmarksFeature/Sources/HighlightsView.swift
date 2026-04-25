import FeaturesSupport
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

struct HighlightsView: View {
    @StateObject var viewModel: HighlightsViewModel

    var body: some View {
        NoorList {
            NoorSection(viewModel.items) { item in
                NoorListItem(
                    image: .init(.bookmark, color: item.collection.color.color),
                    title: .text(l(item.collection.localizationKey)),
                    accessory: .textWithDisclosureIndicator(NumberFormatter.shared.format(item.count))
                ) {
                    viewModel.showDetails(item)
                }
            }
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
    }
}

struct HighlightColorView: View {
    @StateObject var viewModel: HighlightsColorViewModel

    var body: some View {
        Group {
            if viewModel.items.isEmpty {
                DataUnavailableView(
                    title: l("highlights.no-data.title"),
                    text: l("highlights.no-data.text"),
                    image: .bookmark
                )
            } else {
                NoorList {
                    NoorSection(viewModel.items) { item in
                        highlightRow(item)
                    }
                    .onDelete(action: viewModel.deleteItem)
                }
            }
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
    }

    private func highlightRow(_ item: HighlightsColorViewModel.Item) -> some View {
        let verse = item.ayah
        let lineColor = viewModel.collection.color.color.opacity(QuranHighlights.opacity)
        return AnnotationListItem(
            subheading: "\(verse.localizedName) \(sura: verse.sura.arabicSuraName)",
            verseText: "\(verse: item.verseText, color: lineColor, lineLimit: 2)",
            noteText: nil,
            modifiedDateText: item.modifiedDate.timeAgo(),
            pageNumberText: NumberFormatter.shared.format(verse.page.pageNumber)
        ) {
            viewModel.navigateTo(item)
        }
    }
}
