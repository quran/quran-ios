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
        allowsCollectionManagement: Bool = true,
        allowsBookmarkDeletion: Bool = true
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.allowsCollectionManagement = allowsCollectionManagement
        self.allowsBookmarkDeletion = allowsBookmarkDeletion
    }

    // MARK: Internal

    @StateObject var viewModel: AyahBookmarkCollectionsViewModel
    let allowsCollectionManagement: Bool
    let allowsBookmarkDeletion: Bool

    var body: some View {
        Group {
            if viewModel.collections.isEmpty {
                noData
            } else {
                NoorList {
                    ForEach(viewModel.collections) { collection in
                        section(for: collection)
                    }
                }
            }
        }
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
        .environment(\.editMode, $viewModel.editMode)
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

    private func deleteCollectionAction(for collection: AyahBookmarkCollection) -> AsyncAction? {
        guard allowsCollectionManagement else {
            return nil
        }
        return {
            await viewModel.deleteCollection(collection)
        }
    }

    @ViewBuilder
    private func section(for collection: AyahBookmarkCollection) -> some View {
        let isExpanded = Binding(
            get: { viewModel.isCollectionExpanded(collection) },
            set: { viewModel.setCollection(collection, expanded: $0) }
        )

        let highlightColor = HighlightColor(collectionName: collection.collection.name)
        let allowsCollectionDeletion = allowsCollectionManagement && highlightColor == nil

        NoorEditableCollapsibleSection(
            title: highlightColor?.localizedName ?? collection.collection.name,
            isExpanded: isExpanded,
            collection.bookmarks,
            showsHeaderDeleteAction: allowsCollectionDeletion && viewModel.editMode.isEditing,
            headerDeleteAction: allowsCollectionDeletion ? deleteCollectionAction(for: collection) : nil
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
