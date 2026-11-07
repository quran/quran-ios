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
            canRefresh: canRefresh,
            refresh: { await refresh() },
            notes: viewModel.filteredNotes,
            searchTerm: viewModel.searchTerm,
            quranFont: viewModel.reading.quranFont,
            showsHighlightsTip: showsHighlightsTip,
            highlightsSummary: highlightsSummary,
            start: { await viewModel.start() },
            selectAction: { viewModel.navigateTo($0) },
            editAction: { viewModel.editNote($0) },
            deleteAction: { viewModel.deleteItem($0) },
            showHighlights: { showHighlights() },
            dismissHighlightsTip: { dismissHighlightsTip() }
        )
    }

    private var canRefresh: Bool {
        #if QURAN_SYNC
        viewModel.canRefresh
        #else
        false
        #endif
    }

    private var showsHighlightsTip: Bool {
        #if QURAN_SYNC
        viewModel.showsHighlightsTip
        #else
        false
        #endif
    }

    private var highlightsSummary: NotesHighlightsSummary? {
        #if QURAN_SYNC
        viewModel.highlightsSummary
        #else
        nil
        #endif
    }

    private func refresh() async {
        #if QURAN_SYNC
        await viewModel.refresh()
        #endif
    }

    private func showHighlights() {
        #if QURAN_SYNC
        viewModel.showHighlights()
        #endif
    }

    private func dismissHighlightsTip() {
        #if QURAN_SYNC
        viewModel.dismissHighlightsTip()
        #endif
    }
}

@MainActor
private struct NotesViewUI: View {
    // MARK: Internal

    @Binding var editMode: EditMode
    @Binding var error: Error?

    let canRefresh: Bool
    let refresh: AsyncAction
    let notes: [NoteItem]
    let searchTerm: String
    let quranFont: QuranFont
    let showsHighlightsTip: Bool
    let highlightsSummary: NotesHighlightsSummary?

    let start: AsyncAction
    let selectAction: ItemAction<NoteItem>
    let editAction: ItemAction<NoteItem>
    let deleteAction: ItemDeletionAction<NoteItem>
    let showHighlights: () -> Void
    let dismissHighlightsTip: () -> Void

    var body: some View {
        content
            .background(Color.systemGroupedBackground)
    }

    private var content: some View {
        Group {
            if notes.isEmpty {
                if isSearching {
                    noResults
                } else if canRefresh {
                    pullableNoData
                } else {
                    noData
                }
            } else {
                NoorList {
                    if showsHighlightsTip, !isSearching {
                        Section {
                            highlightsTip
                                .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                    }
                    NoorSection(notes, onDelete: deleteAction) { note in
                        listItem(note)
                            .listRowInsets(.init(top: 6, leading: 0, bottom: 6, trailing: 0))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                }
                .refreshable(isEnabled: canRefresh, action: refresh)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task { await start() }
        .errorAlert(error: $error)
        .environment(\.editMode, $editMode)
    }

    // MARK: Private

    @ScaledMetric private var highlightsSpacing = 12.0
    @ScaledMetric private var highlightsDotSpacing = 6.0
    @ScaledMetric private var highlightsDotSize = 12.0
    @ScaledMetric private var highlightsCornerRadius = 20.0
    @ScaledMetric private var highlightsMaxWidth = 320.0

    private var isSearching: Bool {
        !searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var noData: some View {
        VStack {
            NoorListEmptyState(
                title: noDataTitle,
                text: noDataText,
                image: .note,
                style: .prominent(imageColor: .accentColor)
            )

            if let highlightsSummary {
                highlightsMoved(highlightsSummary)
            }
        }
    }

    private var highlightsTip: some View {
        TipCard(
            title: l("notes.highlights-tip.title"),
            text: l("notes.highlights-tip.text"),
            image: .highlighter,
            // The yellow is the same in light and dark mode, so the glyph stays dark on it.
            imageColor: .black.opacity(0.75),
            imageBackground: HighlightColor.yellow.color,
            actionTitle: l("notes.highlights.show"),
            action: showHighlights,
            dismiss: dismissHighlightsTip
        )
    }

    private func highlightsMoved(_ summary: NotesHighlightsSummary) -> some View {
        VStack(spacing: highlightsSpacing) {
            HStack(spacing: highlightsDotSpacing) {
                ForEach(summary.colors, id: \.self) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: highlightsDotSize, height: highlightsDotSize)
                }
            }
            .accessibilityHidden(true)

            Text(highlightsMovedText(summary))
                .font(.subheadline)
                .foregroundStyle(Color.secondaryLabel)
                .multilineTextAlignment(.center)

            AccentCapsuleButton(l("notes.highlights.show"), action: showHighlights)
        }
        .padding()
        .frame(maxWidth: highlightsMaxWidth)
        .background(
            Color.secondarySystemGroupedBackground,
            in: RoundedRectangle(cornerRadius: highlightsCornerRadius, style: .continuous)
        )
        .padding(.horizontal)
    }

    private func highlightsMovedText(_ summary: NotesHighlightsSummary) -> String {
        if let count = summary.upgraderCount {
            lFormat("notes.no-data.highlights.count", count)
        } else {
            l("notes.no-data.highlights.text")
        }
    }

    /// Pull-to-refresh needs a scroll view; this one keeps ``noData`` centered.
    private var pullableNoData: some View {
        GeometryReader { proxy in
            ScrollView {
                noData
                    .frame(minWidth: proxy.size.width, minHeight: proxy.size.height)
            }
            .refreshable { await refresh() }
        }
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
            reference: subheadingText(for: note),
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

    private func subheadingText(for note: Note) -> MultipartText {
        // A note from Quran.com can span suras; search matches any of them, so emphasize when any matches.
        let suras = Set(note.verses.map(\.sura))
        let emphasizesSura = suras.contains { !highlightRanges(in: $0.localizedName()).isEmpty }
        let ayahText: MultipartText = "\(ayah: note.startAyah, emphasizingSura: emphasizesSura)"
        if note.verses.count > 1 {
            return "\(ayahText) \(lFormat("notes.verses-count", note.verses.count - 1))"
        } else {
            return ayahText
        }
    }

    private func quranText(_ item: NoteItem) -> MultipartText? {
        guard let text = item.quranText else {
            return nil
        }
        return "\(quran: text, font: quranFont, color: .clear, lineLimit: 2)"
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
        @State var showsHighlightsTip = true

        var body: some View {
            NavigationView {
                NotesViewUI(
                    editMode: $editMode,
                    error: $error,
                    canRefresh: false,
                    refresh: {},
                    notes: items,
                    searchTerm: searchTerm,
                    quranFont: .uthmanicHafs,
                    showsHighlightsTip: showsHighlightsTip,
                    highlightsSummary: nil,
                    start: {},
                    selectAction: { _ in },
                    editAction: { _ in },
                    deleteAction: { item in
                        items = items.filter { $0 != item }
                        return {}
                    },
                    showHighlights: { showsHighlightsTip = false },
                    dismissHighlightsTip: { showsHighlightsTip = false }
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

    var highlightsSummary: NotesHighlightsSummary?

    var body: some View {
        NavigationView {
            NotesViewUI(
                editMode: $editMode,
                error: $error,
                canRefresh: false,
                refresh: {},
                notes: [],
                searchTerm: "",
                quranFont: .uthmanicHafs,
                showsHighlightsTip: false,
                highlightsSummary: highlightsSummary,
                start: {},
                selectAction: { _ in },
                editAction: { _ in },
                deleteAction: { _ in nil },
                showHighlights: {},
                dismissHighlightsTip: {}
            )
            .navigationTitle(l("tab.notes"))
        }
    }
}

#Preview("Empty") {
    NotesEmptyPreview()
}

#Preview("Empty with highlights") {
    NotesEmptyPreview(highlightsSummary: NotesHighlightsSummary(colors: [.yellow, .green, .blue], upgraderCount: 12))
}
