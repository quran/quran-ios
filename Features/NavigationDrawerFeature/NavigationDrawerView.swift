//
//  NavigationDrawerView.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import SwiftUI

struct NavigationDrawerView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        VStack(spacing: 0) {
            header
            tabPicker
                .padding(.horizontal)
                .padding(.bottom, 8)
            searchField
                .padding(.horizontal)
                .padding(.bottom, 8)
            Divider()
            content
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Search

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            TextField(l("navigation_drawer.search_placeholder"), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text(l("navigation_drawer.title"))
                .font(.headline)
            Spacer()
            Button(action: { viewModel.close() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(width: 30, height: 30)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Circle())
            }
            .accessibilityLabel(l("navigation_drawer.close"))
        }
        .padding()
    }

    // MARK: - Tab picker

    private var tabPicker: some View {
        Picker("", selection: $viewModel.selectedTab) {
            ForEach(NavigationDrawerTab.allCases) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.selectedTab {
        case .surah:
            SurahListView(viewModel: viewModel)
        case .juz:
            JuzListView(viewModel: viewModel)
        case .notes:
            NotesListView(viewModel: viewModel)
        case .bookmarks:
            BookmarksListView(viewModel: viewModel)
        }
    }
}

// MARK: - Surah list

private struct SurahListView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        let suras = viewModel.filteredSuras
        if suras.isEmpty {
            EmptySearchPlaceholder()
        } else {
            NoorList {
                surahSections(suras: suras)
            }
        }
    }

    @ViewBuilder
    private func surahSections(suras: [Sura]) -> some View {
        let grouped = Dictionary(grouping: suras, by: { $0.page.startJuz })
        let juzs = grouped.keys.sorted { $0.juzNumber < $1.juzNumber }
        ForEach(juzs) { juz in
            let items = (grouped[juz] ?? []).sorted { $0.suraNumber < $1.suraNumber }
            NoorSection(title: juz.localizedName, items) { sura in
                surahRow(sura: sura)
            }
        }
    }

    private func surahRow(sura: Sura) -> some View {
        let ayahsString = lFormat("verses", table: .android, sura.verses.count)
        let suraType = sura.isMakki ? lAndroid("makki") : lAndroid("madani")
        return NoorListItem(
            title: "\(sura.localizedName(withNumber: true)) \(sura: sura.arabicSuraName)",
            subtitle: .init(text: "\(suraType) - \(ayahsString)", location: .bottom),
            accessory: .text(NumberFormatter.shared.format(sura.page.pageNumber))
        ) {
            viewModel.selectPage(sura.page)
        }
    }
}

// MARK: - Juz list (quarters grouped by juz, matching the home page style)

/// Quarter doesn't conform to Identifiable in QuranKit, so we wrap it for use
/// with NoorSection / SwiftUI.ForEach. Mirrors the QuarterItem pattern in
/// HomeFeature.
private struct DrawerQuarterItem: Identifiable {
    let quarter: Quarter
    var id: Quarter { quarter }
}

private struct JuzListView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        let quarters = viewModel.filteredQuarters
        if quarters.isEmpty {
            EmptySearchPlaceholder()
        } else {
            NoorList {
                quarterSections(quarters: quarters)
            }
        }
    }

    @ViewBuilder
    private func quarterSections(quarters: [Quarter]) -> some View {
        let grouped = Dictionary(grouping: quarters, by: { $0.juz })
        let juzs = grouped.keys.sorted { $0.juzNumber < $1.juzNumber }
        ForEach(juzs) { juz in
            let items = (grouped[juz] ?? [])
                .sorted { $0.quarterNumber < $1.quarterNumber }
                .map(DrawerQuarterItem.init)
            NoorSection(title: juz.localizedName, items) { item in
                quarterRow(quarter: item.quarter)
            }
        }
    }

    private func quarterRow(quarter: Quarter) -> some View {
        let ayah = quarter.firstVerse
        let title: MultipartText = "\(quarter.localizedName) - \(ayah.localizedName) \(sura: ayah.sura.arabicSuraName)"
        return NoorListItem(
            title: title,
            accessory: .text(NumberFormatter.shared.format(ayah.page.pageNumber))
        ) {
            viewModel.selectPage(ayah.page)
        }
    }
}

// MARK: - Notes list

private struct NotesListView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        let notes = viewModel.filteredNotes
        if notes.isEmpty {
            EmptyDataPlaceholder(
                systemImage: "note.text",
                title: viewModel.searchText.isEmpty
                    ? l("navigation_drawer.empty.no_notes")
                    : l("navigation_drawer.empty.no_matching_notes")
            )
        } else {
            List {
                ForEach(notes, id: \.firstVerse) { note in
                    Button {
                        viewModel.selectPage(note.firstVerse.page)
                    } label: {
                        NoteRow(note: note)
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct NoteRow: View {
    let note: Note

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(swiftUIColor(for: note.color))
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(note.note?.isEmpty == false ? note.note! : l("navigation_drawer.note.untitled"))
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                Text("\(note.firstVerse.sura.localizedName(withPrefix: false)) \(note.firstVerse.sura.suraNumber):\(note.firstVerse.ayah)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func swiftUIColor(for color: Note.Color) -> Color {
        switch color {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }
}

// MARK: - Bookmarks list

private struct BookmarksListView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        let bookmarks = viewModel.filteredBookmarks
        if bookmarks.isEmpty {
            EmptyDataPlaceholder(
                systemImage: "bookmark",
                title: viewModel.searchText.isEmpty
                    ? l("navigation_drawer.empty.no_bookmarks")
                    : l("navigation_drawer.empty.no_matching_bookmarks")
            )
        } else {
            NoorList {
                NoorBasicSection {
                    ForEach(bookmarks) { bookmark in
                        let sura = bookmark.page.startSura
                        NoorListItem(
                            title: "\(sura.localizedName(withNumber: true)) \(sura: sura.arabicSuraName)",
                            subtitle: .init(
                                text: lFormat("navigation_drawer.bookmark.page", bookmark.page.pageNumber),
                                location: .bottom
                            ),
                            accessory: .text(NumberFormatter.shared.format(bookmark.page.pageNumber))
                        ) {
                            viewModel.selectPage(bookmark.page)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Generic empty placeholder

private struct EmptyDataPlaceholder: View {
    let systemImage: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty search placeholder

private struct EmptySearchPlaceholder: View {
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 32))
                .foregroundColor(.secondary.opacity(0.4))
            Text(l("navigation_drawer.empty.no_results"))
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
