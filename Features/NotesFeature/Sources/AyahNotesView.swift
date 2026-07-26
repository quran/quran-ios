#if QURAN_SYNC
//
//  AyahNotesView.swift
//

import Foundation
import Localization
import NoorUI
import QuranAnnotations
import QuranKit
import SwiftUI
import UIx

@MainActor
struct AyahNotesView: View {
    // MARK: Lifecycle

    init(
        viewModel: AyahNotesViewModel,
        addAction: @escaping @MainActor @Sendable () -> Void,
        editAction: @escaping @MainActor @Sendable (Note) -> Void
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.addAction = addAction
        self.editAction = editAction
    }

    // MARK: Internal

    @StateObject var viewModel: AyahNotesViewModel

    var body: some View {
        AyahNotesContent(
            editMode: $viewModel.editMode,
            notes: viewModel.notes,
            addAction: addAction,
            editAction: editAction,
            deleteAction: { await viewModel.deleteNote($0) }
        )
        .task { await viewModel.start() }
        .errorAlert(error: $viewModel.error)
    }

    // MARK: Private

    private let addAction: @MainActor @Sendable () -> Void
    private let editAction: @MainActor @Sendable (Note) -> Void
}

@MainActor
private struct AyahNotesContent: View {
    @Binding var editMode: EditMode

    let notes: [Note]
    let addAction: @MainActor @Sendable () -> Void
    let editAction: @MainActor @Sendable (Note) -> Void
    let deleteAction: @MainActor @Sendable (Note) async -> Void

    var body: some View {
        VStack {
            NoorList {
                NoorSection(notes) { note in
                    NoteItemView(note: note, editAction: editAction)
                }
                .onDelete(action: deleteAction)
            }

            ProminentRoundedButton(label: l("notes.new"), image: .plus) {
                addAction()
            }
            .padding()
            .background(Color.systemGroupedBackground)
        }
        .background(Color.systemGroupedBackground)
        .environment(\.editMode, $editMode)
    }
}

@MainActor
private struct NoteItemView: View {
    let note: Note
    let editAction: @MainActor @Sendable (Note) -> Void

    var body: some View {
        NoorListItem(
            title: .text(note.text),
            subtitle: .init(
                text: .text(note.modifiedDate.timeAgo()),
                location: .bottom
            ),
            accessory: .disclosureIndicator,
            action: { editAction(note) }
        )
        .lineLimit(2)
    }
}

@MainActor
private struct AyahNotesPreview: View {
    @State private var editMode = EditMode.inactive

    var body: some View {
        let quran = Quran.hafsMadani1405
        let verses = Array(quran.suras[15].verses[34 ... 35])
        let notes = [
            Note(
                id: "first",
                text: "The “if Allah willed” excuse — the same argument every nation made.",
                startAyah: verses[0],
                endAyah: verses[1],
                modifiedDate: Date().addingTimeInterval(-2 * 60 * 60)
            ),
            Note(
                id: "second",
                text: "Khutbah idea: the psychology of blaming destiny.",
                startAyah: verses[0],
                endAyah: verses[1],
                modifiedDate: Date().addingTimeInterval(-24 * 60 * 60)
            ),
        ]

        NavigationView {
            AyahNotesContent(
                editMode: $editMode,
                notes: notes,
                addAction: {},
                editAction: { _ in },
                deleteAction: { _ in }
            )
            .navigationTitle("An-Nahl, Ayah 35–36")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
}

#Preview {
    AyahNotesPreview()
}
#endif
