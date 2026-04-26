#if QURAN_SYNC
    import Localization
    import NoorUI
    import QuranAnnotations
    import SwiftUI
    import UIx

    struct SyncedNotesView: View {
        @StateObject var viewModel: SyncedNotesViewModel

        var body: some View {
            SyncedNotesViewUI(
                editMode: $viewModel.editMode,
                error: $viewModel.error,
                notes: viewModel.notes,
                start: { await viewModel.start() },
                selectAction: { viewModel.navigateTo($0) },
                deleteAction: { await viewModel.deleteItem($0) }
            )
        }
    }

    private struct SyncedNotesViewUI: View {
        @Binding var editMode: EditMode
        @Binding var error: Error?

        let notes: [SyncedNoteItem]
        let start: AsyncAction
        let selectAction: ItemAction<SyncedNoteItem>
        let deleteAction: AsyncItemAction<SyncedNoteItem>

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
            .task { await start() }
            .errorAlert(error: $error)
            .environment(\.editMode, $editMode)
        }

        private var noData: some View {
            DataUnavailableView(
                title: l("notes.no-data.title"),
                text: l("notes.no-data.text"),
                image: .note
            )
        }

        private func listItem(_ item: SyncedNoteItem) -> some View {
            guard let ayah = item.note.firstVerse else {
                return AnyView(EmptyView())
            }

            let localizedVerse = ayah.localizedName
            let arabicSuraName = ayah.sura.arabicSuraName
            let ayahCount = item.note.verses.count
            let numberOfAyahs = ayahCount > 1 ? lFormat("notes.verses-count", ayahCount - 1) : ""
            let verseColor = (item.highlightColor?.color ?? .clear).opacity(QuranHighlights.opacity)

            return AnyView(
                AnnotationListItem(
                    subheading: "\(localizedVerse) \(sura: arabicSuraName) \(numberOfAyahs)",
                    verseText: "\(verse: item.verseText, color: verseColor, lineLimit: 2)",
                    noteText: item.note.body,
                    modifiedDateText: item.note.modifiedDate.timeAgo(),
                    pageNumberText: NumberFormatter.shared.format(ayah.page.pageNumber)
                ) {
                    selectAction(item)
                }
            )
        }
    }
#endif
