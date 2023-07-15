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

struct BookmarksView: View {
    @StateObject var viewModel: BookmarksViewModel

    var body: some View {
        BookmarksViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            bookmarks: viewModel.bookmarks,
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
            deleteAction: { await viewModel.deleteItem($0) }
        )
    }
}

private struct BookmarksViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let bookmarks: [PageBookmark]

    let start: AsyncAction
    let selectAction: ItemAction<PageBookmark>
    let deleteAction: AsyncItemAction<PageBookmark>

    var body: some View {
        Group {
            if bookmarks.isEmpty {
                noData
            } else {
                NoorList {
                    NoorSection(bookmarks) { bookmark in
                        listItem(bookmark)
                    }
                    .onDelete(action: deleteAction)
                }
            }
        }
        .task(start)
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    private var noData: some View {
        DataUnavailableView(
            title: l("bookmarks.no-data.title"),
            text: l("bookmarks.no-data.text"),
            image: .bookmark
        )
    }

    private func listItem(_ bookmark: PageBookmark) -> some View {
        let ayah = bookmark.page.firstVerse
        return SimpleListItem(
            image: .init(.bookmark, color: .red),
            title: "\(ayah.sura.localizedName()) \(sura: ayah.sura.arabicSuraName)",
            subtitle: .init(text: bookmark.creationDate.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(bookmark.page.pageNumber))
        ) {
            selectAction(bookmark)
        }
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
                    start: {},
                    selectAction: { _ in },
                    deleteAction: { item in items = items.filter { $0 != item } }
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
