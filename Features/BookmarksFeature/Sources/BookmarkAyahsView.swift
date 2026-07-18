//
//  BookmarkAyahsView.swift
//

import Localization
import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

@MainActor
struct BookmarkAyahsView: View {
    @ObservedObject var viewModel: BookmarkAyahsViewModel

    var body: some View {
        NoorList {
            NoorBasicSection(title: l("ayah.menu.highlight")) {
                #if QURAN_SYNC
                HighlightColorPicker(
                    selectedColor: viewModel.selectedHighlightColor,
                    onSelect: { await viewModel.selectHighlight($0) },
                    onRemove: viewModel.highlightSelection == .none
                        ? nil
                        : { await viewModel.selectHighlight(nil) }
                )
                .disabled(viewModel.isUpdatingHighlight)
                #else
                HighlightColorPicker(
                    selectedColor: viewModel.selectedHighlightColor,
                    onSelect: { await viewModel.selectHighlight($0) }
                )
                .disabled(viewModel.isUpdatingHighlight)
                #endif
            }

            #if QURAN_SYNC
            NoorBasicSection(title: l("bookmarks.collections.mine")) {
                ForEach(viewModel.displayedCollections, id: \.collection.id) { collection in
                    collectionRow(collection)
                }

                NoorListItem(
                    image: .init(.plusCircle, color: .appIdentity),
                    title: .text(l("bookmarks.collections.new")),
                    titleColor: .appIdentity,
                    action: { viewModel.presentAddCollection() }
                )
            }
            #endif
        }
        #if QURAN_SYNC
        .task { await viewModel.start() }
            .addBookmarkCollectionAlert(viewModel: viewModel)
        #endif
            .errorAlert(error: $viewModel.error)
    }

    #if QURAN_SYNC
    private func collectionRow(_ collection: AyahBookmarkCollection) -> some View {
        let selection = viewModel.collectionSelection(for: collection)
        return NoorListItem(
            image: .init(collection.displayImage, color: collection.displayImageColor),
            title: .text(collection.displayName),
            accessory: collectionAccessory(selection),
            action: { await viewModel.toggleCollection(collection) }
        )
        .disabled(viewModel.isUpdatingCollection(collection))
        .accessibilityValue(collectionAccessibilityValue(selection))
    }

    private func collectionAccessory(
        _ selection: BookmarkAyahsViewModel.CollectionSelection
    ) -> NoorListItem.Accessory {
        switch selection {
        case .unselected:
            .image(.checkmark_unchecked, color: .tertiaryLabel)
        case .mixed:
            .image(.checkmark_indeterminate, color: .appIdentity)
        case .selected:
            .image(.checkmark_checked, color: .appIdentity)
        }
    }

    private func collectionAccessibilityValue(
        _ selection: BookmarkAyahsViewModel.CollectionSelection
    ) -> String {
        switch selection {
        case .unselected:
            l("bookmarks.editor.collection.unselected")
        case .mixed:
            l("bookmarks.editor.collection.mixed")
        case .selected:
            l("bookmarks.editor.collection.selected")
        }
    }
    #endif
}

#if QURAN_SYNC
private extension View {
    @MainActor
    func addBookmarkCollectionAlert(viewModel: BookmarkAyahsViewModel) -> some View {
        alert(
            l("bookmarks.collections.add"),
            isPresented: Binding(
                get: { viewModel.isPresentingAddCollection },
                set: { viewModel.isPresentingAddCollection = $0 }
            )
        ) {
            TextField(
                l("bookmarks.collections.new.placeholder"),
                text: Binding(
                    get: { viewModel.newCollectionName },
                    set: { viewModel.newCollectionName = $0 }
                )
            )
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("bookmarks.collections.add")) {
                Task { await viewModel.createPendingCollection() }
            }
        }
    }
}
#endif
