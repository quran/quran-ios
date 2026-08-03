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
import QuranLocalization
import QuranText
import SwiftUI
import UIx

@MainActor
struct NotesView: View {
    @StateObject var viewModel: NotesViewModel

    var body: some View {
        NotesViewUI(
            editMode: $viewModel.editMode,
            error: $viewModel.error,
            shouldShowSyncBanner: shouldShowSyncBanner,
            dismissSyncBanner: { dismissSyncBanner() },
            signInAction: { await signIn() },
            notes: viewModel.filteredNotes,
            searchTerm: viewModel.searchTerm,
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
            editAction: { viewModel.editNote($0) },
            deleteAction: { await viewModel.deleteItem($0) }
        )
    }

    private var shouldShowSyncBanner: Bool {
        #if QURAN_SYNC
        viewModel.shouldShowSyncBanner
        #else
        false
        #endif
    }

    private func dismissSyncBanner() {
        #if QURAN_SYNC
        viewModel.dismissSyncBanner()
        #endif
    }

    private func signIn() async {
        #if QURAN_SYNC
        await viewModel.loginToQuranCom()
        #endif
    }
}

@MainActor
private struct NotesViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let shouldShowSyncBanner: Bool
    let dismissSyncBanner: @MainActor @Sendable () -> Void
    let signInAction: AsyncAction
    let notes: [NoteItem]
    let searchTerm: String

    let start: AsyncAction
    let selectAction: ItemAction<NoteItem>
    let editAction: ItemAction<NoteItem>
    let deleteAction: AsyncItemAction<NoteItem>

    var body: some View {
        VStack(spacing: 0) {
            if shouldShowSyncBanner, !isSearching {
                SyncSignInCard(
                    title: l("notes.sync.title"),
                    subtitle: l("notes.sync.body"),
                    actionLabel: l("bookmarks.sync.action"),
                    dismiss: dismissSyncBanner,
                    signInAction: signInAction
                )
                .padding()
            }

            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemGroupedBackground)
    }

    private var content: some View {
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
                            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    .onDelete(action: deleteAction)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    private var isSearching: Bool {
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var noData: some View {
        NoorListEmptyState(
            title: noDataTitle,
            text: noDataText,
            image: .note,
            style: .prominent(imageColor: .accentColor)
        )
    }

    private var noDataTitle: String {
        #if QURAN_SYNC
        l("notes.sync.no-data.title")
        #else
        l("notes.no-data.title")
        #endif
    }

    private var noDataText: String {
        #if QURAN_SYNC
        l("notes.sync.no-data.text")
        #else
        l("notes.no-data.text")
        #endif
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
        let ayah = note.startAyah
        let page = ayah.page
        #if QURAN_SYNC
        let noteColor: Color? = nil
        #else
        let noteColor: Color? = note.color.color
        #endif
        let noteText = item.noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        return NoteCard(
            reference: subheadingText(ayah: ayah, ayahCount: note.verses.count),
            location: "\(page.startJuz.localizedName) · \(page.localizedName)",
            quranText: quranText(item),
            noteText: noteText.isEmpty ? nil : titleText(for: noteText),
            modifiedDate: note.modifiedDate.timeAgo(),
            noteColor: noteColor,
            editAccessibilityHint: l("ayah.menu.edit-note"),
            selectAction: { selectAction(item) },
            editAction: { editAction(item) }
        )
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

    private func subheadingText(ayah: AyahNumber, ayahCount: Int) -> MultipartText {
        let emphasizesSura = !highlightRanges(in: ayah.sura.localizedName()).isEmpty
        let ayahText: MultipartText = "\(ayah: ayah, emphasizingSura: emphasizesSura)"
        if ayahCount > 1 {
            return "\(ayahText) \(lFormat("notes.verses-count", ayahCount - 1))"
        } else {
            return ayahText
        }
    }

    private func quranText(_ item: NoteItem) -> MultipartText? {
        guard let text = item.quranText else {
            return nil
        }
        return "\(quran: text, color: .clear, lineLimit: 2)"
    }
}

#if !QURAN_SYNC
struct NotesView_Previews: PreviewProvider {
    struct Preview: View {
        static let quranText: QuranText = "وَإِذۡ قَالَ مُوسَىٰ لِقَوۡمِهِۦ يَٰقَوۡمِ إِنَّكُمۡ ظَلَمۡتُمۡ أَنفُسَكُم بِٱتِّخَاذِكُمُ ٱلۡعِجۡلَ فَتُوبُوٓاْ إِلَىٰ بَارِئِكُمۡ فَٱقۡتُلُوٓاْ أَنفُسَكُمۡ ذَٰلِكُمۡ خَيۡرٞ لَّكُمۡ عِندَ بَارِئِكُمۡ فَتَابَ عَلَيۡكُمۡۚ إِنَّهُۥ هُوَ ٱلتَّوَّابُ ٱلرَّحِيمُ"
        static let quran = Quran.hafsMadani1405

        static var staticItems: [NoteItem] {
            [
                NoteItem(
                    note: Note(
                        verses: [quran.suras[2].verses[3]],
                        modifiedDate: Date(),
                        text: nil,
                        color: .purple
                    ),
                    quranText: quranText
                ),
                NoteItem(
                    note: Note(
                        verses: Set(quran.suras[2].verses),
                        modifiedDate: Date().addingTimeInterval(-24 * 60),
                        text: "Remind myself to memorize it",
                        color: .green
                    ),
                    quranText: quranText
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
                    shouldShowSyncBanner: false,
                    dismissSyncBanner: {},
                    signInAction: {},
                    notes: items,
                    searchTerm: searchTerm,
                    start: {},
                    selectAction: { _ in },
                    editAction: { _ in },
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

                    EditModeButton(editMode: $editMode)
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
#endif

private struct NotesEmptyPreview: View {
    @State private var editMode: EditMode = .inactive
    @State private var error: Error?

    let showsSignInCard: Bool

    var body: some View {
        NavigationView {
            NotesViewUI(
                editMode: $editMode,
                error: $error,
                shouldShowSyncBanner: showsSignInCard,
                dismissSyncBanner: {},
                signInAction: {},
                notes: [],
                searchTerm: "",
                start: {},
                selectAction: { _ in },
                editAction: { _ in },
                deleteAction: { _ in }
            )
            .navigationTitle(l("tab.notes"))
        }
    }
}

#Preview("Empty — Sign In") {
    NotesEmptyPreview(showsSignInCard: true)
}

#Preview("Empty — Dismissed") {
    NotesEmptyPreview(showsSignInCard: false)
}
