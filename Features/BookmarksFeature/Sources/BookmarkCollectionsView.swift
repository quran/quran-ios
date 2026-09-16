#if QURAN_SYNC
//
//  BookmarkCollectionsView.swift
//

import AnnotationsService
import FeaturesSupport
import Localization
import NoorUI
import QuranAnnotations
import SwiftUI
import UIx

@MainActor
struct BookmarkCollectionsView: View {
    @StateObject var viewModel: BookmarkCollectionsViewModel

    init(viewModel: BookmarkCollectionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        BookmarkCollectionsContent(viewModel: viewModel)
    }
}

@MainActor
private struct BookmarkCollectionsContent: View {
    @ObservedObject var viewModel: BookmarkCollectionsViewModel

    var body: some View {
        NoorList {
            if viewModel.shouldShowSyncBanner {
                NoorBasicSection {
                    SyncSignInCard(
                        title: l("bookmarks.sync.title"),
                        subtitle: l("bookmarks.sync.body"),
                        actionLabel: l("bookmarks.sync.action"),
                        dismiss: { viewModel.dismissSyncBanner() },
                        signInAction: { await viewModel.loginToQuranCom() }
                    )
                    .listRowInsets(.zero)
                    .listRowBackground(Color.clear)
                }
            }

            ContinueReadingSection(
                title: "Reading bookmarks",
                readingBookmarks: viewModel.readingBookmarks,
                lastPages: [],
                selectReadingBookmark: { viewModel.navigateTo($0) },
                selectLastPage: { _ in }
            )

            NoorBasicSection(title: l("bookmarks.collections.colored")) {
                ColoredBookmarksView(items: coloredBookmarks) { viewModel.showHighlights($0) }
            }

            NoorBasicSection(title: l("bookmarks.collections.mine")) {
                if viewModel.displayedCollections.isEmpty {
                    NoorListEmptyState(
                        title: l("bookmarks.collections.no-data.title"),
                        text: l("bookmarks.collections.no-data.text"),
                        image: .folderOutline
                    )
                }

                NoorListRows(
                    viewModel.displayedCollections,
                    canDelete: { $0.canDelete },
                    onDelete: { collection in
                        { await viewModel.requestDeleteCollection(collection) }
                    }
                ) { collection in
                    collectionRow(
                        title: collection.displayName,
                        image: collection.displayImage,
                        imageColor: collection.displayImageColor,
                        count: collection.bookmarks.count,
                        action: { viewModel.showCollection(collection) }
                    )
                }

                NoorListItem(
                    image: .init(.plusCircle, color: .appIdentity),
                    title: .text(l("bookmarks.collections.new")),
                    titleColor: .appIdentity,
                    action: .sync { viewModel.presentAddCollection() }
                )
                .deleteDisabled(true)
            }
        }
        .task { await viewModel.start() }
        .addCollectionAlert(viewModel: viewModel)
        .collectionDeleteConfirmation(
            item: $viewModel.collectionPendingDeletion,
            delete: { await viewModel.deleteCollection($0) }
        )
        .errorAlert(error: $viewModel.error)
        .environment(\.editMode, $viewModel.editMode)
    }

    private var coloredBookmarks: [ColoredBookmarksView.Item] {
        HighlightColor.alphabeticallySortedColors
            .map { color in
                ColoredBookmarksView.Item(color: color, count: viewModel.highlights.values.count { $0 == color })
            }
            .sorted { $0.count > $1.count }
    }

    private func collectionRow(
        title: String,
        image: NoorSystemImage,
        imageColor: Color,
        count: Int,
        action: @escaping Action
    ) -> some View {
        NoorListItem(
            image: .init(image, color: imageColor),
            title: .text(title),
            subtitle: .init(
                text: .text(NumberFormatter.shared.format(count)),
                location: .trailing
            ),
            accessory: .disclosureIndicator,
            action: .sync { action() }
        )
    }
}

private extension View {
    @MainActor
    func addCollectionAlert(viewModel: BookmarkCollectionsViewModel) -> some View {
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
