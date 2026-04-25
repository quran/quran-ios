//
//  NavigationDrawerView.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import Localization
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
            List {
                ForEach(suras) { sura in
                    Button {
                        viewModel.selectPage(sura.page)
                    } label: {
                        DrawerRow(
                            leading: "\(sura.suraNumber)",
                            title: sura.localizedName(withPrefix: false),
                            subtitle: sura.isMakki
                                ? l("navigation_drawer.surah.makki")
                                : l("navigation_drawer.surah.madani"),
                            isCurrent: sura.page == viewModel.currentPage
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Juz list

private struct JuzListView: View {
    @ObservedObject var viewModel: NavigationDrawerViewModel

    var body: some View {
        let juzs = viewModel.filteredJuzs
        if juzs.isEmpty {
            EmptySearchPlaceholder()
        } else {
            List {
                ForEach(juzs) { juz in
                    Button {
                        viewModel.selectPage(juz.page)
                    } label: {
                        DrawerRow(
                            leading: "\(juz.juzNumber)",
                            title: juz.localizedName,
                            subtitle: nil,
                            isCurrent: juz.page == viewModel.currentPage
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Row

private struct DrawerRow: View {
    let leading: String
    let title: String
    let subtitle: String?
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(leading)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 32, alignment: .center)
                .padding(.vertical, 4)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            if isCurrent {
                Image(systemName: "location.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
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
            List {
                ForEach(bookmarks) { bookmark in
                    Button {
                        viewModel.selectPage(bookmark.page)
                    } label: {
                        DrawerRow(
                            leading: "\(bookmark.page.pageNumber)",
                            title: bookmark.page.startSura.localizedName(withPrefix: false),
                            subtitle: lFormat("navigation_drawer.bookmark.page", bookmark.page.pageNumber),
                            isCurrent: bookmark.page == viewModel.currentPage
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.plain)
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
