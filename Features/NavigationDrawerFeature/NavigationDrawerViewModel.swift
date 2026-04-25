//
//  NavigationDrawerViewModel.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Combine
import Localization
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

    /// All searchable representations of a sura's name — English + Arabic,
    /// with and without the "Surah" / "سورة" prefix, and the standalone
    /// arabicSuraName. Lets users search regardless of UI locale or whether
    /// they include the prefix.
    private func suraSearchTerms(_ sura: Sura) -> [String] {
        [
            sura.localizedName(withPrefix: false, language: .english),
            sura.localizedName(withPrefix: true, language: .english),
            sura.localizedName(withPrefix: false, language: .arabic),
            sura.localizedName(withPrefix: true, language: .arabic),
            sura.arabicSuraName,
        ].map { $0.lowercased() }
    }

    /// Returns the surahs filtered by `searchText`. Matches against any
    /// English / Arabic name form (with or without prefix) and the surah
    /// number.
    var filteredSuras: [Sura] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return quran.suras }
        return quran.suras.filter { sura in
            suraSearchTerms(sura).contains { $0.contains(query) }
                || String(sura.suraNumber).contains(query)
        }
    }

    /// Returns the quarters filtered by `searchText`. Matches:
    /// - the quarter's localized name (e.g. "Hizb 1, 1/4")
    /// - the parent juz number
    /// - the page number
    /// - the starting sura's name (en/ar with/without prefix)
    /// - any quarter whose page range overlaps a sura matching the query
    ///   (so typing a mid-juz sura name like "Yaseen" still returns the
    ///   quarters that contain it)
    var filteredQuarters: [Quarter] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else { return quran.quarters }

        // Page ranges of suras whose names match the query.
        let matchingSuraPageRanges: [(Int, Int)] = quran.suras
            .filter { suraSearchTerms($0).contains { $0.contains(query) } }
            .map { ($0.firstVerse.page.pageNumber, $0.lastVerse.page.pageNumber) }

        return quran.quarters.filter { quarter in
            let page = quarter.firstVerse.page.pageNumber
            return quarter.localizedName.lowercased().contains(query)
                || suraSearchTerms(quarter.firstVerse.sura).contains { $0.contains(query) }
                || String(quarter.juz.juzNumber).contains(query)
                || String(page).contains(query)
                || matchingSuraPageRanges.contains { page >= $0.0 && page <= $0.1 }
        }
    }

    /// Returns notes filtered by `searchText`. Matches the note text and any
    /// name form of the first verse's sura.
    var filteredNotes: [Note] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = notes.sorted { $0.modifiedDate > $1.modifiedDate }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { note in
            (note.note ?? "").lowercased().contains(query)
                || suraSearchTerms(note.firstVerse.sura).contains { $0.contains(query) }
        }
    }

    /// Returns bookmarks filtered by `searchText`. Matches any name form of
    /// the bookmarked page's starting sura and the page number.
    var filteredBookmarks: [PageBookmark] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        let sorted = pageBookmarks.sorted { $0.creationDate > $1.creationDate }
        guard !query.isEmpty else { return sorted }
        return sorted.filter { bookmark in
            suraSearchTerms(bookmark.page.startSura).contains { $0.contains(query) }
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
