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
                editMode: $viewModel.editMode,
                error: $viewModel.error,
                collections: viewModel.collections,
                isCollectionExpanded: { viewModel.isCollectionExpanded($0) },
                setCollectionExpanded: { viewModel.setCollection($0, expanded: $1) },
                start: { await viewModel.start() },
                selectBookmark: { viewModel.navigateTo($0) },
                deleteCollectionAction: { await viewModel.deleteCollection($0) },
                deleteBookmarkAction: { await viewModel.deleteBookmark($0) }
            )
        }
    }

    @MainActor
    private struct CollectionsViewUI: View {
        // MARK: Internal

        @Binding var editMode: EditMode
        @Binding var error: Error?

        let collections: [CollectionWithAyahBookmarks]
        let isCollectionExpanded: (CollectionWithAyahBookmarks) -> Bool
        let setCollectionExpanded: (CollectionWithAyahBookmarks, Bool) -> Void
        let start: AsyncAction
        let selectBookmark: ItemAction<CollectionAyahBookmark>
        let deleteCollectionAction: AsyncItemAction<CollectionWithAyahBookmarks>
        let deleteBookmarkAction: AsyncItemAction<CollectionAyahBookmark>

        var body: some View {
            Group {
                if collections.isEmpty {
                    noData
                } else {
                    NoorList {
                        ForEach(collections) { collection in
                            let isExpanded = Binding(
                                get: { isCollectionExpanded(collection) },
                                set: { setCollectionExpanded(collection, $0) }
                            )
                            NoorSection(
                                title: collection.collection.name,
                                isExpanded: isExpanded,
                                collection.bookmarks
                            ) { bookmark in
                                bookmarkItem(bookmark)
                            }
                            .onHeaderDelete {
                                await deleteCollectionAction(collection)
                            }
                            .headerActions(headerActions(for: collection))
                            .onDelete(action: deleteBookmarkAction)
                        }
                    }
                }
            }
            .task { await start() }
            .errorAlert(error: $error)
            .environment(\.editMode, $editMode)
        }

        // MARK: Private

        private var noData: some View {
            DataUnavailableView(
                title: l("bookmarks.collections.no-data.title"),
                text: l("bookmarks.collections.no-data.text"),
                image: .folder
            )
        }

        private func headerActions(for collection: CollectionWithAyahBookmarks) -> [NoorSectionHeaderAction] {
            guard editMode.isEditing else {
                return []
            }
            return [
                NoorSectionHeaderAction(image: .delete, tintColor: .red) {
                    await deleteCollectionAction(collection)
                },
            ]
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
