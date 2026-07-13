#if QURAN_SYNC
//
//  AyahBookmarkCollectionsView.swift
//
//  Created by Ahmed Nabil on 2026-05-05.
//

import Localization
import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

@MainActor
struct AyahBookmarkCollectionsView: View {
    // MARK: Lifecycle

    init(
        viewModel: AyahBookmarkCollectionsViewModel,
        allowsBookmarkDeletion: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.allowsBookmarkDeletion = allowsBookmarkDeletion
    }

    // MARK: Internal

    @StateObject var viewModel: AyahBookmarkCollectionsViewModel
    let allowsBookmarkDeletion: Bool

    var body: some View {
        NoorList {
            AyahBookmarkCollectionsContent(
                viewModel: viewModel,
                allowsBookmarkDeletion: allowsBookmarkDeletion
            )
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
    }
}

@MainActor
struct AyahBookmarkCollectionsContent: View {
    @ObservedObject var viewModel: AyahBookmarkCollectionsViewModel
    let allowsBookmarkDeletion: Bool
    @State private var isExpanded = true

    var body: some View {
        Group {
            if let collection = viewModel.collection {
                section(for: collection)
            } else {
                noData
            }
        }
    }

    // MARK: Private

    private var noData: some View {
        DataUnavailableView(
            title: l("bookmarks.collections.no-data.title"),
            text: l("bookmarks.collections.no-data.text"),
            image: .bookmark
        )
    }

    private var deleteBookmarkAction: AsyncItemAction<AyahCollectionBookmark>? {
        guard allowsBookmarkDeletion else {
            return nil
        }
        return { bookmark in
            await viewModel.deleteBookmark(bookmark)
        }
    }

    @ViewBuilder
    private func section(for collection: AyahBookmarkCollection) -> some View {
        let highlightColor = HighlightColor(collectionName: collection.collection.name)

        NoorEditableCollapsibleSection(
            title: highlightColor?.localizedName ?? collection.collection.name,
            isExpanded: $isExpanded,
            collection.bookmarks,
            showsHeaderDeleteAction: false,
            headerDeleteAction: nil
        ) { bookmark in
            bookmarkItem(bookmark, iconColor: highlightColor?.color)
        }
        .onDelete(action: deleteBookmarkAction)
    }

    private func bookmarkItem(_ bookmark: AyahCollectionBookmark, iconColor: Color?) -> some View {
        NoorListItem(
            image: .init(.bookmark, color: iconColor ?? .red),
            title: "\(bookmark.ayah.sura.localizedName()) \(sura: bookmark.ayah.sura.arabicSuraName)",
            subtitle: .init(text: bookmark.ayah.localizedName, location: .bottom),
            accessory: .text(NumberFormatter.shared.format(bookmark.ayah.page.pageNumber))
        ) {
            viewModel.navigateTo(bookmark)
        }
    }
}
#endif
