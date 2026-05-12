#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionsView.swift
    //
    //  Created by Ahmed Nabil on 2026-05-05.
    //

    import Localization
    import NoorUI
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

        @ViewBuilder
        private func section(for collection: AyahBookmarkCollection) -> some View {
            let isExpanded = Binding(
                get: { viewModel.isCollectionExpanded(collection) },
                set: { viewModel.setCollection(collection, expanded: $0) }
            )

            NoorBasicSection(title: collection.collection.name, isExpanded: isExpanded) {
                ForEach(collection.bookmarks) { bookmark in
                    bookmarkItem(bookmark)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.deleteBookmark(bookmark)
                                }
                            } label: {
                                Label(lAndroid("delete"), systemImage: "trash")
                            }
                        }
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    Task {
                        await viewModel.deleteCollection(collection)
                    }
                } label: {
                    Label(lAndroid("delete"), systemImage: "trash")
                }
            }
        }

        private func bookmarkItem(_ bookmark: AyahCollectionBookmark) -> some View {
            NoorListItem(
                image: .init(.bookmark, color: .red),
                title: "\(bookmark.ayah.sura.localizedName()) \(sura: bookmark.ayah.sura.arabicSuraName)",
                subtitle: .init(text: bookmark.ayah.localizedName, location: .bottom),
                accessory: .text(NumberFormatter.shared.format(bookmark.ayah.page.pageNumber))
            ) {
                viewModel.navigateTo(bookmark)
            }
        }
    }
#endif
