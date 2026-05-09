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

        init(viewModel: AyahBookmarkCollectionPickerViewModel, addCollection: @escaping AsyncAction) {
            _viewModel = StateObject(wrappedValue: viewModel)
            self.addCollection = addCollection
        }

        // MARK: Internal

        @StateObject var viewModel: AyahBookmarkCollectionPickerViewModel
        let addCollection: AsyncAction

        var body: some View {
            NoorList {
                Section {
                    NoorListItem(
                        image: .init(.bookmark, color: .red),
                        title: .text(l("ayah-bookmark.save-reading-bookmark")),
                        action: { await viewModel.saveReadingBookmark() }
                    )
                }

                Section(header: Text(l("ayah-bookmark.save-to-collection"))) {
                    if viewModel.collections.isEmpty {
                        emptyCollectionsItem
                    } else {
                        ForEach(viewModel.collections) { collection in
                            collectionItem(collection)
                        }
                    }

                    NoorListItem(
                        image: .init(.folder),
                        title: .text(l("bookmarks.collections.add")),
                        action: addCollection
                    )
                }
            }
            .task { await viewModel.start() }
            .errorAlert(error: $viewModel.error)
        }

        // MARK: Private

        private var emptyCollectionsItem: some View {
            NoorListItem(
                image: .init(.folder),
                title: .text(l("ayah-bookmark.collection-picker.no-data.title")),
                subtitle: .init(text: l("ayah-bookmark.collection-picker.no-data.text"), location: .bottom)
            )
        }

        private func collectionItem(_ collection: AyahBookmarkCollection) -> some View {
            let highlightColor = HighlightColor(collectionName: collection.collection.name)
            return NoorListItem(
                image: .init(.folder, color: highlightColor?.color),
                title: .text(highlightColor?.localizedName ?? collection.collection.name),
                accessory: .image(viewModel.isSelected(collection) ? .checkmark_checked : .checkmark_unchecked),
                action: { viewModel.toggleSelection(for: collection) }
            )
        }
    }
#endif
