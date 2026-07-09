#if QURAN_SYNC
//
//  SyncedNotesView.swift
//
//  Created by Ahmed Nabil on 2026-05-16.
//

import Localization
import NoorUI
import QuranKit
import SwiftUI
import UIx

struct SyncedNotesView: View {
    @StateObject var viewModel: SyncedNotesViewModel
    let selectAction: ItemAction<SyncedNoteItem>

    var body: some View {
        SyncedNotesViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            notes: viewModel.filteredNotes,
            searchTerm: viewModel.searchTerm,
            start: { await viewModel.start() },
            selectAction: selectAction,
            deleteAction: { await viewModel.deleteItem($0) }
        )
    }
}

private struct SyncedNotesViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let notes: [SyncedNoteItem]
    let searchTerm: String
    let start: AsyncAction
    let selectAction: ItemAction<SyncedNoteItem>
    let deleteAction: AsyncItemAction<SyncedNoteItem>

    var body: some View {
        Group {
            if notes.isEmpty {
                if isSearching {
                    noResults
                } else {
                    noData
                }
            } else {
                NoorList {
                    NoorSection(notes) { note in
                        listItem(note)
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

    private var isSearching: Bool {
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var noData: some View {
        DataUnavailableView(
            title: l("notes.no-data.title"),
            text: l("notes.no-data.text"),
            image: .note
        )
    }

    private var noResults: some View {
        DataUnavailableView(
            title: lFormat("notes.search.no-results.title", searchTerm),
            text: l("notes.search.no-results.text"),
            image: .search
        )
    }

    private func listItem(_ item: SyncedNoteItem) -> some View {
        let note = item.note
        let ayah = note.startAyah
        let page = ayah.page
        let ayahCount = note.verses.count
        let numberOfAyahs = ayahCount > 1 ? lFormat("notes.verses-count", ayahCount - 1) : ""
        return NoorListItem(
            subheading: subheadingText(
                localizedVerse: ayah.localizedName,
                arabicSuraName: ayah.sura.arabicSuraName,
                numberOfAyahs: numberOfAyahs
            ),
            rightPretitle: "\(verse: item.verseText, color: Color.clear, lineLimit: 2)",
            title: titleText(for: note.note.trimmingCharacters(in: .whitespacesAndNewlines)),
            subtitle: .init(text: note.modifiedDate.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(page.pageNumber))
        ) {
            selectAction(item)
        }
    }

    private func highlightRanges(in text: String) -> [HighlightingRange] {
        let term = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty,
              let range = text.range(of: term, options: .caseInsensitive)
        else {
            return []
        }
        return [HighlightingRange(range, fontWeight: .heavy)]
    }

    private func titleText(for noteText: String) -> MultipartText {
        let ranges = highlightRanges(in: noteText)
        if ranges.isEmpty {
            return .text(noteText)
        }
        return "\(noteText, highlighting: ranges)"
    }

    private func subheadingText(localizedVerse: String, arabicSuraName: String, numberOfAyahs: String) -> MultipartText {
        let ranges = highlightRanges(in: localizedVerse)
        if ranges.isEmpty {
            return "\(localizedVerse) \(sura: arabicSuraName) \(numberOfAyahs)"
        }
        return "\(localizedVerse, highlighting: ranges) \(sura: arabicSuraName) \(numberOfAyahs)"
    }
}
#endif
