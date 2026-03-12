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
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
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

    let start: AsyncAction
    let selectAction: ItemAction<PageBookmark>
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
                    NoorSection(bookmarks) { bookmark in
                        listItem(bookmark)
                    }
                    .onDelete(action: deleteAction)
                }
            }
        }
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    private var emptyState: some View {
        VStack(spacing: 16) {
            #if QURAN_SYNC
                if shouldShowSyncBanner {
                    syncBanner
                        .padding(.horizontal)
                        .padding(.top, 12)
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
    @ScaledMetric private var buttonCornerRadius = Dimensions.cornerRadius
    @ScaledMetric private var containerCornerRadius = Dimensions.cornerRadius

    let dismiss: () -> Void
    let signInAction: @MainActor () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "link.icloud.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sync your bookmarks")
                        .font(.headline)

                    Text("Sign in to Quran.com to keep your bookmarks available across devices.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }

            AsyncButton(action: { await signInAction() }) {
                Text("Sign In")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
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
                    start: {},
                    selectAction: { _ in },
                    deleteAction: { item in items = items.filter { $0 != item } },
                    dismissSyncBanner: {},
                    signInAction: {}
                )
                .navigationTitle("Bookmarks")
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
