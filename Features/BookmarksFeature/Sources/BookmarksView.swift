//
//  BookmarksView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-13.
//

import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
struct BookmarksView: View {
    @StateObject var viewModel: BookmarksViewModel

    var body: some View {
        BookmarksViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            bookmarks: viewModel.bookmarks,
            shouldShowSyncBanner: viewModel.shouldShowSyncBanner,
            shouldShowHighlights: viewModel.shouldShowHighlights,
            highlightCount: viewModel.highlightCount,
            start: { await viewModel.start() },
            observeHighlights: { await viewModel.observeHighlights() },
            selectAction: { viewModel.navigateTo($0) },
            selectHighlightsAction: { viewModel.showHighlights() },
            deleteAction: { await viewModel.deleteItem($0) },
            dismissSyncBanner: { viewModel.dismissSyncBanner() },
            signInAction: { await viewModel.loginToQuranCom() }
        )
    }
}

@MainActor
private struct BookmarksViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let bookmarks: [PageBookmark]
    let shouldShowSyncBanner: Bool
    let shouldShowHighlights: Bool
    let highlightCount: Int

    let start: AsyncAction
    let observeHighlights: AsyncAction
    let selectAction: ItemAction<PageBookmark>
    let selectHighlightsAction: () -> Void
    let deleteAction: AsyncItemAction<PageBookmark>
    let dismissSyncBanner: () -> Void
    let signInAction: @MainActor () async -> Void

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                emptyState
            } else {
                NoorList {
                    #if QURAN_SYNC
                        if shouldShowSyncBanner {
                            NoorBasicSection {
                                syncBanner
                            }
                        }
                    #endif
                    if shouldShowHighlights {
                        NoorBasicSection {
                            highlightsItem
                        }
                    }
                    NoorSection(bookmarks) { bookmark in
                        listItem(bookmark)
                    }
                    .onDelete(action: deleteAction)
                }
            }
        }
        .task { await start() }
        .task { await observeHighlights() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    @ViewBuilder
    private var emptyState: some View {
        if showsTopSections {
            VStack(spacing: 16) {
                NoorList {
                    #if QURAN_SYNC
                        if shouldShowSyncBanner {
                            NoorBasicSection {
                                syncBanner
                            }
                        }
                    #endif

                    if shouldShowHighlights {
                        NoorBasicSection {
                            highlightsItem
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, ContentDimension.interPageSpacing)

                noData
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .background(Color.systemGroupedBackground)
        } else {
            VStack(spacing: 16) {
                noData
            }
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

    private var showsTopSections: Bool {
        #if QURAN_SYNC
            shouldShowSyncBanner || shouldShowHighlights
        #else
            shouldShowHighlights
        #endif
    }

    private var highlightsItem: some View {
        NoorListItem(
            leadingView: AnyView(HighlightPaletteIcon()),
            title: .text(l("highlights.title")),
            accessory: .textWithDisclosureIndicator(NumberFormatter.shared.format(highlightCount))
        ) {
            selectHighlightsAction()
        }
    }

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
    @ScaledMetric private var closeButtonInset = ContentDimension.interSpacing
    @ScaledMetric private var containerCornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var containerPadding = ContentDimension.interPageSpacing + (ContentDimension.interSpacing / 2)
    @ScaledMetric private var contentSpacing = ContentDimension.interPageSpacing
    @ScaledMetric private var titleSpacing = ContentDimension.interSpacing / 2
    @ScaledMetric private var trailingSpacing = ContentDimension.interSpacing

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
            NavigationView {
                BookmarksViewUI(
                    editMode: $editMode,
                    error: $error,
                    bookmarks: items,
                    shouldShowSyncBanner: true,
                    shouldShowHighlights: true,
                    highlightCount: 6,
                    start: {},
                    observeHighlights: {},
                    selectAction: { _ in },
                    selectHighlightsAction: {},
                    deleteAction: { item in items = items.filter { $0 != item } },
                    dismissSyncBanner: {},
                    signInAction: {}
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
