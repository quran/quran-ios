//
//  NavigationDrawerViewModel.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Combine
import QuranAnnotations
import QuranKit
import QuranTextKit
import SwiftUI

@MainActor
final class NavigationDrawerViewModel: ObservableObject {
    // MARK: - State

    @Published var selectedTab: NavigationDrawerTab = .surah
    @Published var searchText: String = ""

    // MARK: - Inputs

    let quran: Quran
    let currentPage: Page
    let notes: [Note]
    let pageBookmarks: [PageBookmark]

    // Callback fired when the user picks a destination. The presenter is
    // responsible for dismissing the drawer and navigating the reading view.
    let onSelectPage: (Page) -> Void
    let onClose: () -> Void

    // MARK: - Lifecycle

    init(
        quran: Quran,
        currentPage: Page,
        notes: [Note],
        pageBookmarks: [PageBookmark],
        onSelectPage: @escaping (Page) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.quran = quran
        self.currentPage = currentPage
        self.notes = notes
        self.pageBookmarks = pageBookmarks
        self.onSelectPage = onSelectPage
        self.onClose = onClose
    }

    // MARK: - Filtering

    /// Returns the surahs filtered by `searchText`. Matches against the
    /// localized name and the surah number.
    var filteredSuras: [Sura] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return quran.suras }
        return quran.suras.filter { sura in
            sura.localizedName(withPrefix: false).lowercased().contains(query)
                || String(sura.suraNumber).contains(query)
        }
    }

    /// Returns the juzs filtered by `searchText`. Matches against the
    /// localized name and the juz number.
    var filteredJuzs: [Juz] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return quran.juzs }
        return quran.juzs.filter { juz in
            juz.localizedName.lowercased().contains(query)
                || String(juz.juzNumber).contains(query)
        }
    }

    /// Returns notes filtered by `searchText`. Matches the note text and the
    /// localized sura name of the first verse.
    var filteredNotes: [Note] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = notes.sorted { $0.modifiedDate > $1.modifiedDate }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { note in
            (note.note ?? "").lowercased().contains(query)
                || note.firstVerse.sura.localizedName(withPrefix: false).lowercased().contains(query)
        }
    }

    /// Returns bookmarks filtered by `searchText`. Matches the localized sura
    /// name of the bookmarked page and the page number.
    var filteredBookmarks: [PageBookmark] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = pageBookmarks.sorted { $0.creationDate > $1.creationDate }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { bookmark in
            bookmark.page.startSura.localizedName(withPrefix: false).lowercased().contains(query)
                || String(bookmark.page.pageNumber).contains(query)
        }
    }

    // MARK: - Actions

    func selectPage(_ page: Page) {
        onSelectPage(page)
    }

    func close() {
        onClose()
    }
}
