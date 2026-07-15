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

    init(viewModel: AyahBookmarkCollectionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // MARK: Internal

    @StateObject var viewModel: AyahBookmarkCollectionsViewModel

    var body: some View {
        AyahBookmarkCollectionDetails(viewModel: viewModel, collection: viewModel.collection)
            .task { await viewModel.start() }
            .renameCollectionAlert(viewModel: viewModel)
            .errorAlert(error: $viewModel.error)
            .environment(\.editMode, $viewModel.editMode)
    }
}

@MainActor
private struct AyahBookmarkCollectionDetails: View {
    @ObservedObject var viewModel: AyahBookmarkCollectionsViewModel
    let collection: AyahBookmarkCollection

    var body: some View {
        VStack {
            if collection.bookmarks.isEmpty {
                emptyCollection
            } else {
                filledCollection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
    }

    // MARK: Private

    private var highlightColor: HighlightColor? {
        collection.kind.highlightColor
    }

    private var filledCollection: some View {
        NoorList {
            Section {
                ForEach(collection.bookmarks) { bookmark in
                    bookmarkRow(bookmark)
                }
                .onDelete { offsets in
                    let bookmarks = offsets.map { collection.bookmarks[$0] }
                    Task {
                        for bookmark in bookmarks {
                            await viewModel.deleteBookmark(bookmark)
                        }
                    }
                }
            } footer: {
                Text(l("bookmarks.collections.ayahs.delete-hint"))
                    .font(.body)
                    .foregroundStyle(Color.tertiaryLabel)
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    .textCase(nil)
            }
        }
    }

    private var emptyCollection: some View {
        NoorListEmptyState(
            title: lAndroid("bookmarks_list_empty"),
            text: emptyStateText,
            image: .bookmark,
            style: .prominent(
                imageColor: highlightColor?.color ?? Color.appIdentity
            )
        )
    }

    private var emptyStateText: String {
        if let highlightColor {
            return lFormat(
                "bookmarks.collections.ayahs.no-data.colored.text",
                highlightColor.localizedName.lowercased()
            )
        }
        return l("bookmarks.collections.ayahs.no-data.text")
    }

    private func bookmarkRow(_ bookmark: AyahCollectionBookmark) -> some View {
        NoorListItem(
            rightPretitle: "\(verse: viewModel.ayahTexts[bookmark.ayah] ?? " ", color: .clear, lineLimit: 2)",
            title: bookmarkLocation(bookmark),
            titleColor: .secondaryLabel,
            action: { viewModel.navigateTo(bookmark) }
        )
        .accessibilityHint(l("bookmarks.collections.ayahs.open-hint"))
    }

    private func bookmarkLocation(_ bookmark: AyahCollectionBookmark) -> MultipartText {
        let ayah = bookmark.ayah
        return "\(ayah.localizedNameWithSuraNumber) \(sura: ayah.sura.arabicSuraName) · \(ayah.page.localizedName)"
    }
}

private extension View {
    @MainActor
    func renameCollectionAlert(viewModel: AyahBookmarkCollectionsViewModel) -> some View {
        alert(
            l("bookmarks.collections.rename"),
            isPresented: Binding(
                get: { viewModel.isPresentingRenameCollection },
                set: { viewModel.isPresentingRenameCollection = $0 }
            )
        ) {
            TextField(
                l("bookmarks.collections.new.placeholder"),
                text: Binding(
                    get: { viewModel.pendingCollectionName },
                    set: { viewModel.pendingCollectionName = $0 }
                )
            )
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("bookmarks.collections.rename")) {
                Task { await viewModel.renamePendingCollection() }
            }
        }
    }
}
#endif
