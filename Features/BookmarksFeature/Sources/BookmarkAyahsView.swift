#if QURAN_SYNC
//
//  BookmarkAyahsView.swift
//

import AnnotationsService
import Localization
import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

@MainActor
struct BookmarkAyahsView: View {
    @ObservedObject var viewModel: BookmarkAyahsViewModel
    let bottomBarsHeight: @MainActor () -> CGFloat

    var body: some View {
        BookmarkAyahsContent(viewModel: viewModel)
            .enableToastPresenter(bottomBarsHeight: bottomBarsHeight)
    }
}

@MainActor
private struct BookmarkAyahsContent: View {
    @ObservedObject var viewModel: BookmarkAyahsViewModel

    @Environment(\.showToast) private var showToast

    var body: some View {
        NoorList {
            if viewModel.isCollectionsIntroVisible {
                NoorBasicSection {
                    IntroTipCard(
                        image: .starFilled,
                        text: l("bookmarks.editor.intro"),
                        dismiss: {
                            withAnimation(NoorAnimation.standard) {
                                viewModel.dismissCollectionsIntro()
                            }
                        }
                    )
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                }
            }

            NoorBasicSection(title: l("ayah.menu.highlight")) {
                HighlightColorPicker(
                    selectedColor: viewModel.selectedHighlightColor,
                    partiallySelectedColors: viewModel.partiallySelectedHighlightColors,
                    onSelect: { await viewModel.selectHighlight($0) },
                    onRemove: viewModel.highlightSelection == .none
                        ? nil
                        : { await viewModel.selectHighlight(nil) }
                )
                .disabled(viewModel.isUpdatingHighlight)
            }

            NoorBasicSection(title: l("bookmarks.collections.mine")) {
                ForEach(viewModel.displayedCollections, id: \.id) { collection in
                    collectionRow(collection)
                }

                NoorListItem(
                    image: .init(.plusCircle, color: .accentColor),
                    title: .text(l("bookmarks.collections.new")),
                    titleColor: .accentColor,
                    action: .sync { viewModel.presentAddCollection() }
                )
            }
        }
        .task { await viewModel.start() }
        .collectionNameAlert(
            l("bookmarks.collections.add"),
            state: $viewModel.nameAlert,
            name: $viewModel.newCollectionName,
            submit: {
                if let toast = await viewModel.createPendingCollection() {
                    showToast?(toast)
                }
            }
        )
        .errorAlert(error: $viewModel.error)
    }

    private func collectionRow(_ collection: AyahBookmarkCollection) -> some View {
        let selection = viewModel.collectionSelection(for: collection)
        return NoorListItem(
            image: .init(collection.displayImage, color: collection.displayImageColor),
            title: .text(collection.displayName),
            accessory: collectionAccessory(selection),
            action: .async { await viewModel.toggleCollection(collection) }
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
            .image(.checkmark_indeterminate, color: .accentColor)
        case .selected:
            .image(.checkmark_checked, color: .accentColor)
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
}
#endif
