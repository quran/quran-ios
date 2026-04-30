//
//  NotesView.swift
//
//
//  Created by Mohamed Afifi on 2023-07-15.
//

import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

struct NotesView: View {
    @StateObject var viewModel: NotesViewModel

    var body: some View {
        NotesViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            notes: viewModel.filteredNotes,
            searchTerm: viewModel.searchTerm,
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
            deleteAction: { await viewModel.deleteItem($0) }
        )
    }
}

private struct NotesViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let notes: [NoteItem]
    let searchTerm: String

    let start: AsyncAction
    let selectAction: ItemAction<NoteItem>
    let deleteAction: AsyncItemAction<NoteItem>

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

    private func listItem(_ item: NoteItem) -> some View {
        let note = item.note
        let ayah = note.firstVerse
        let page = ayah.page
        let localizedVerse = note.firstVerse.localizedName
        let arabicSuraName = note.firstVerse.sura.arabicSuraName
        let ayahCount = note.verses.count
        let numberOfAyahs = ayahCount > 1 ? lFormat("notes.verses-count", ayahCount - 1) : ""
        let color = note.color.color.opacity(QuranHighlights.opacity)
        let noteText = note.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return NoorListItem(
            subheading: subheadingText(localizedVerse: localizedVerse, arabicSuraName: arabicSuraName, numberOfAyahs: numberOfAyahs),
            rightPretitle: "\(verse: item.verseText, color: color, lineLimit: 2)",
            title: titleText(for: noteText),
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

struct NotesView_Previews: PreviewProvider {
    struct Preview: View {
        static let ayahText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"
        static let quran = Quran.hafsMadani1405

        static var staticItems: [NoteItem] {
            [
                NoteItem(
                    note: Note(
                        verses: [quran.suras[2].verses[3]],
                        modifiedDate: Date(),
                        note: nil,
                        color: .purple
                    ),
                    verseText: ayahText
                ),
                NoteItem(
                    note: Note(
                        verses: Set(quran.suras[2].verses),
                        modifiedDate: Date().addingTimeInterval(-24 * 60),
                        note: "Remind myself to memorize it",
                        color: .green
                    ),
                    verseText: ayahText
                ),
            ]
        }

        @State var items: [NoteItem] = staticItems
        @State var editMode: EditMode = .inactive
        @State var error: Error? = nil
        @State var searchTerm: String = ""

        var body: some View {
            NavigationView {
                NotesViewUI(
                    editMode: $editMode,
                    error: $error,
                    notes: items,
                    searchTerm: searchTerm,
                    start: {},
                    selectAction: { _ in },
                    deleteAction: { item in items = items.filter { $0 != item } }
                )
                .navigationTitle("Notes")
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
