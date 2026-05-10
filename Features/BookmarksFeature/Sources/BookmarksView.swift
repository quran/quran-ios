//
//  BookmarksView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import AnnotationsService
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
struct BookmarksView: View {
    @StateObject var viewModel: BookmarksViewModel

    init(viewModel: BookmarksViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        BookmarksViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            bookmarks: viewModel.bookmarks,
            readingBookmark: viewModel.readingBookmark,
            shouldShowSyncBanner: viewModel.shouldShowSyncBanner,
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
            selectReadingBookmark: { viewModel.navigateToReadingBookmark() },
            deleteAction: { await viewModel.deleteItem($0) },
            dismissSyncBanner: { viewModel.dismissSyncBanner() },
            signInAction: { await viewModel.loginToQuranCom() },
            showCollectionsAction: viewModel.showCollectionsAction,
            showOldPageBookmarksAction: viewModel.showOldPageBookmarksAction
        )
    }
}

@MainActor
private struct BookmarksViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let bookmarks: [PageBookmark]
    let readingBookmark: QuranReadingBookmark?
    let shouldShowSyncBanner: Bool

    let start: AsyncAction
    let selectAction: ItemAction<PageBookmark>
    let selectReadingBookmark: () -> Void
    let deleteAction: AsyncItemAction<PageBookmark>
    let dismissSyncBanner: () -> Void
    let signInAction: @MainActor () async -> Void
    let showCollectionsAction: AsyncAction?
    let showOldPageBookmarksAction: AsyncAction?

    var body: some View {
        Group {
            if showsEmptyState {
                emptyState
            } else {
                NoorList {
                    listSections(includeBookmarks: !bookmarks.isEmpty)
                }
            }
        }
        .task {
            await start()
        }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    private var showsEmptyState: Bool {
        #if QURAN_SYNC
            bookmarks.isEmpty && readingBookmark == nil
        #else
            bookmarks.isEmpty
        #endif
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            #if QURAN_SYNC
                NoorList {
                    listSections(includeBookmarks: false)
                }
            #endif
            noData
        }
    }

    private var noData: some View {
        DataUnavailableView(
            title: l("bookmarks.no-data.title"),
            text: l("bookmarks.no-data.text"),
            image: .bookmark
        )
    }

    private var syncBanner: some View {
        BookmarksSyncBanner(
            dismiss: dismissSyncBanner,
            signInAction: signInAction
        )
    }

    #if QURAN_SYNC
        private var oldPageBookmarksRow: some View {
            NoorListItem(
                image: .init(.bookmark, color: .secondary),
                title: .text(l("bookmarks.old-page-bookmarks")),
                subtitle: .init(text: NumberFormatter.shared.format(bookmarks.count), location: .trailing),
                accessory: .disclosureIndicator,
                action: showOldPageBookmarksAction
            )
        }

        private var collectionsRow: some View {
            NoorListItem(
                image: .init(.folder, color: .accentColor),
                title: .text(l("bookmarks.collections")),
                accessory: .disclosureIndicator,
                action: showCollectionsAction
            )
        }
    #endif

    @ViewBuilder
    private func listSections(includeBookmarks: Bool) -> some View {
        #if QURAN_SYNC
            if shouldShowSyncBanner {
                NoorBasicSection {
                    syncBanner
                }
            }

            if showOldPageBookmarksAction != nil {
                NoorBasicSection {
                    oldPageBookmarksRow
                }
            }

            if showCollectionsAction != nil {
                NoorBasicSection {
                    collectionsRow
                }
            }

            if let readingBookmark {
                NoorBasicSection(title: l("reading-bookmark.my-title")) {
                    readingBookmarkItem(readingBookmark)
                }
            }
        #endif

        if includeBookmarks {
            NoorSection(bookmarks) { bookmark in
                listItem(bookmark)
            }
            .onDelete(action: deleteAction)
        }
    }

    #if QURAN_SYNC
        private func readingBookmarkItem(_ bookmark: QuranReadingBookmark) -> some View {
            let ayah = bookmark.ayah
            return NoorListItem(
                image: .init(.bookmark, color: .red),
                title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
                subtitle: .init(text: bookmark.lastUpdated.timeAgo(), location: .bottom),
                accessory: .text(NumberFormatter.shared.format(bookmark.page.pageNumber))
            ) {
                selectReadingBookmark()
            }
        }
    #endif

    private func listItem(_ bookmark: PageBookmark) -> some View {
        let ayah = bookmark.page.firstVerse
        return NoorListItem(
            image: .init(.bookmark, color: .red),
            title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
            subtitle: .init(text: bookmark.creationDate.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(bookmark.page.pageNumber))
        ) {
            selectAction(bookmark)
        }
    }
}

@MainActor
private struct BookmarksSyncBanner: View {
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

struct BookmarksView_Previews: PreviewProvider {
    struct Preview: View {
        static var staticItems: [PageBookmark] {
            let pages = Quran.hafsMadani1405.pages.shuffled()
            return (0 ..< 100).map { i in
                PageBookmark(page: pages[i], creationDate: Date())
            }
        }

        @State var items: [PageBookmark] = staticItems
        @State var editMode: EditMode = .inactive
        @State var error: Error? = nil

        var body: some View {
            let showCollectionsAction: AsyncAction? = {}
            NavigationView {
                BookmarksViewUI(
                    editMode: $editMode,
                    error: $error,
                    bookmarks: items,
                    readingBookmark: .page(Quran.hafsMadani1405.pages[0], .distantPast),
                    shouldShowSyncBanner: true,
                    start: {},
                    selectAction: { _ in },
                    selectReadingBookmark: {},
                    deleteAction: { item in items = items.filter { $0 != item } },
                    dismissSyncBanner: {},
                    signInAction: {},
                    showCollectionsAction: showCollectionsAction,
                    showOldPageBookmarksAction: {}
                )
                .navigationTitle(lAndroid("menu_bookmarks"))
                .toolbar {
                    if items.isEmpty {
                        Button("Populate") { items = Self.staticItems }
                    } else {
                        Button("Empty") { items = [] }
                    }

                    if error == nil {
                        Button("Error") { error = URLError(.notConnectedToInternet) }
                    }

                    Button(editMode == .inactive ? "Edit" : "Done") {
                        withAnimation { editMode = editMode == .inactive ? .active : .inactive }
                    }
                }
            }
        }
    }

    // MARK: Internal

    static var previews: some View {
        VStack {
            Preview()
        }
    }
}
