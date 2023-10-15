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
            notes: viewModel.notes,
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

    let start: AsyncAction
    let selectAction: ItemAction<NoteItem>
    let deleteAction: AsyncItemAction<NoteItem>

    var body: some View {
        Group {
            if notes.isEmpty {
                noData
            } else {
                NoorList {
                    NoorSection(notes) { note in
                        listItem(note)
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
            title: l("notes.no-data.title"),
            text: l("notes.no-data.text"),
            image: .note
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
        return NoorListItem(
            subheading: "\(localizedVerse) \(sura: arabicSuraName) \(numberOfAyahs)",
            rightPretitle: "\(verse: item.verseText, color: color, lineLimit: 2)",
            title: .text(note.note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""),
            subtitle: .init(text: note.modifiedDate.timeAgo(), location: .bottom),
            accessory: .text(NumberFormatter.shared.format(page.pageNumber))
        ) {
            selectAction(item)
        }
    }
}

struct NotesView_Previews: PreviewProvider {
    struct Preview: View {
        static let ayahText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"
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

        var body: some View {
            NavigationView {
                NotesViewUI(
                    editMode: $editMode,
                    error: $error,
                    notes: items,
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
