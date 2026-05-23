#if QURAN_SYNC
    //
    //  AyahBookmarkCollectionPickerView.swift
    //
    //  Created by Ahmed Nabil on 2026-05-09.
    //

    import Localization
    import NoorUI
    import QuranAnnotations
    import SwiftUI
    import UIx

    @MainActor
    struct AyahBookmarkCollectionPickerView: View {
        // MARK: Lifecycle

        init(viewModel: AyahBookmarkCollectionPickerViewModel) {
            _viewModel = StateObject(wrappedValue: viewModel)
        }

        // MARK: Internal

        @StateObject var viewModel: AyahBookmarkCollectionPickerViewModel

        var body: some View {
            NoorList {
                Section {
                    readingBookmarkItem
                }

                if !viewModel.highlightCollections.isEmpty {
                    Section(header: Text(l("ayah-bookmark.save-to-highlight"))) {
                        ForEach(viewModel.highlightCollections) { collection in
                            collectionItem(collection)
                        }
                    }
                }

                Section(header: Text(l("ayah-bookmark.save-to-collection"))) {
                    if viewModel.bookmarkCollections.isEmpty {
                        emptyCollectionsItem
                    } else {
                        ForEach(viewModel.bookmarkCollections) { collection in
                            collectionItem(collection)
                        }
                    }
                }
            }
            .task { await viewModel.start() }
            .errorAlert(error: $viewModel.error)
        }

        // MARK: Private

        private var readingBookmarkItem: some View {
            NoorListItem(
                image: .init(
                    viewModel.isSelectedVerseReadingBookmark ? .bookmark : .bookmarkOutline,
                    color: viewModel.isSelectedVerseReadingBookmark ? .red : nil
                ),
                title: .text(
                    viewModel.isSelectedVerseReadingBookmark
                        ? l("ayah-bookmark.remove-reading-bookmark")
                        : l("ayah-bookmark.save-reading-bookmark")
                ),
                action: { await viewModel.toggleReadingBookmark() }
            )
        }

        private var emptyCollectionsItem: some View {
            NoorListItem(
                image: .init(.folder),
                title: .text(l("ayah-bookmark.collection-picker.no-data.title")),
                subtitle: .init(text: l("ayah-bookmark.collection-picker.no-data.text"), location: .bottom)
            )
        }

        private func collectionItem(_ collection: AyahBookmarkCollection) -> some View {
            let highlightColor = AyahBookmarkCollectionPickerViewModel.highlightColor(for: collection)
            return NoorListItem(
                image: .init(.folder, color: highlightColor?.color),
                title: .text(highlightColor?.localizedName ?? collection.collection.name),
                accessory: .image(viewModel.isSelected(collection) ? .checkmark_checked : .checkmark_unchecked),
                action: { viewModel.toggleSelection(for: collection) }
            )
        }
    }
#endif
