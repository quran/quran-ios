#if QURAN_SYNC
    //
    //  CollectionsView.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Localization
    import MobileSync
    import NoorUI
    import QuranKit
    import ReadingService
    import SwiftUI
    import UIx

    @MainActor
    struct CollectionsView: View {
        @StateObject var viewModel: CollectionsViewModel

        var body: some View {
            CollectionsViewUI(
                error: $viewModel.error,
                collections: viewModel.collections,
                isCollectionExpanded: { viewModel.isCollectionExpanded($0) },
                setCollectionExpanded: { viewModel.setCollection($0, expanded: $1) },
                start: { await viewModel.start() },
                selectBookmark: { viewModel.navigateTo($0) },
                deleteAction: { await viewModel.deleteItem($0) }
            )
        }
    }

    @MainActor
    private struct CollectionsViewUI: View {
        // MARK: Internal

        @Binding var error: Error?

        let collections: [CollectionWithAyahBookmarks]
        let isCollectionExpanded: (CollectionWithAyahBookmarks) -> Bool
        let setCollectionExpanded: (CollectionWithAyahBookmarks, Bool) -> Void
        let start: AsyncAction
        let selectBookmark: ItemAction<CollectionAyahBookmark>
        let deleteAction: AsyncItemAction<CollectionWithAyahBookmarks>

        var body: some View {
            Group {
                if collections.isEmpty {
                    noData
                } else {
                    NoorList {
                        ForEach(collections) { collection in
                            NoorBasicSection {
                                collectionItem(collection)

                                if isCollectionExpanded(collection) {
                                    ForEach(collection.bookmarks) { bookmark in
                                        bookmarkItem(bookmark)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .task { await start() }
            .errorAlert(error: $error)
        }

        // MARK: Private

        private var noData: some View {
            DataUnavailableView(
                title: l("bookmarks.collections.no-data.title"),
                text: l("bookmarks.collections.no-data.text"),
                image: .folder
            )
        }

        private func collectionItem(_ collection: CollectionWithAyahBookmarks) -> some View {
            NoorListItem(
                image: .init(.folder, color: .accentColor),
                title: .text(collection.collection.name),
                subtitle: .init(
                    text: lFormat("bookmarks.collections.ayah-count", collection.bookmarks.count),
                    location: .bottom
                ),
                accessory: .image(isCollectionExpanded(collection) ? .chevronDown : .chevronRight)
            ) {
                setCollectionExpanded(collection, !isCollectionExpanded(collection))
            }
            .swipeActions {
                Button(role: .destructive) {
                    Task {
                        await deleteAction(collection)
                    }
                } label: {
                    Label(l("button.delete"), systemImage: "trash")
                }
            }
        }

        @ViewBuilder
        private func bookmarkItem(_ bookmark: CollectionAyahBookmark) -> some View {
            if let ayah = AyahNumber(quran: ReadingPreferences.shared.reading.quran, sura: Int(bookmark.sura), ayah: Int(bookmark.ayah)) {
                NoorListItem(
                    image: .init(.bookmark, color: .red),
                    title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
                    subtitle: .init(text: ayah.localizedName, location: .bottom),
                    accessory: .text(NumberFormatter.shared.format(ayah.page.pageNumber))
                ) {
                    selectBookmark(bookmark)
                }
            }
        }
    }
#endif
