#if QURAN_SYNC
//
//  BookmarkCollectionsView.swift
//

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
                    BookmarkCollectionsSyncBanner(
                        dismiss: { viewModel.dismissSyncBanner() },
                        signInAction: { await viewModel.loginToQuranCom() }
                    )
                }
            }

            NoorBasicSection(title: l("bookmarks.collections.colored")) {
                ForEach(HighlightColor.sortedColors, id: \.self) { color in
                    collectionRow(
                        title: color.localizedName,
                        image: .bookmark,
                        imageColor: color.color,
                        collection: highlightCollection(for: color)
                    )
                }
            }

            NoorBasicSection(title: l("bookmarks.collections.mine")) {
                if let collection = viewModel.oldPageBookmarksCollection {
                    collectionRow(
                        title: l("bookmarks.old-page-bookmarks"),
                        image: .book,
                        imageColor: .secondaryLabel,
                        collection: collection
                    )
                    .deleteDisabled(true)
                }

                if userCollections.isEmpty, viewModel.oldPageBookmarksCollection == nil {
                    NoorListEmptyState(
                        title: l("bookmarks.collections.no-data.title"),
                        text: l("bookmarks.collections.no-data.text"),
                        image: .folderOutline
                    )
                }

                ForEach(userCollections) { collection in
                    collectionRow(
                        title: collection.collection.name,
                        image: .folder,
                        imageColor: .appIdentity,
                        collection: collection
                    )
                }
                .onDelete { offsets in
                    let collections = offsets.map { userCollections[$0] }
                    Task {
                        for collection in collections {
                            await viewModel.deleteCollection(collection)
                        }
                    }
                }

                NoorListItem(
                    image: .init(.plusCircle, color: .appIdentity),
                    title: .text(l("bookmarks.collections.new")),
                    titleColor: .appIdentity,
                    action: { viewModel.presentAddCollection() }
                )
                .deleteDisabled(true)
            }
        }
        .task { await viewModel.start() }
        .addCollectionAlert(viewModel: viewModel)
        .errorAlert(error: $viewModel.error)
        .environment(\.editMode, $viewModel.editMode)
    }

    private var userCollections: [AyahBookmarkCollection] {
        viewModel.collections.filter {
            $0.collection.name != AyahBookmarkCollectionName.oldPageBookmarks &&
                HighlightColor(collectionName: $0.collection.name) == nil
        }
    }

    private func highlightCollection(for color: HighlightColor) -> AyahBookmarkCollection? {
        viewModel.collections.first {
            $0.collection.name == color.collectionName
        }
    }

    private func collectionRow(
        title: String,
        image: NoorSystemImage,
        imageColor: Color,
        collection: AyahBookmarkCollection?
    ) -> some View {
        NoorListItem(
            image: .init(image, color: imageColor),
            title: .text(title),
            subtitle: .init(
                text: NumberFormatter.shared.format(collection?.bookmarks.count ?? 0),
                location: .trailing
            ),
            accessory: .disclosureIndicator,
            action: collectionAction(for: collection)
        )
    }

    private func collectionAction(for collection: AyahBookmarkCollection?) -> AsyncAction? {
        guard let collection else {
            return nil
        }
        return { viewModel.showCollection(collection) }
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

@MainActor
private struct BookmarkCollectionsSyncBanner: View {
    @ScaledMetric private var closeButtonInset = 8.0
    @ScaledMetric private var containerCornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var containerPadding = 16.0
    @ScaledMetric private var contentSpacing = 12.0
    @ScaledMetric private var titleSpacing = 4.0
    @ScaledMetric private var trailingSpacing = 8.0

    let dismiss: () -> Void
    let signInAction: @MainActor () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            HStack(alignment: .top, spacing: contentSpacing) {
                NoorSystemImage.bookmark.image
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: titleSpacing) {
                    Text(l("bookmarks.sync.title"))
                        .font(.headline)

                    Text(l("bookmarks.sync.body"))
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryLabel)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: trailingSpacing)

                Button(action: dismiss) {
                    NoorSystemImage.cancel.image
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(Color.secondaryLabel)
                        .padding(closeButtonInset)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lAndroid("cancel"))
            }

            ProminentRoundedButton(label: l("bookmarks.sync.action")) {
                await signInAction()
            }
        }
        .padding(containerPadding)
        .background(Color.secondarySystemBackground)
        .overlay(
            RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous)
                .stroke(Color.accentColor.opacity(0.18), lineWidth: 1)
        )
        .background(Color.accentColor.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: containerCornerRadius, style: .continuous))
    }
}
#endif
