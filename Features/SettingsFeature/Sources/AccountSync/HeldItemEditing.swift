#if QURAN_SYNC
//
//  HeldItemEditing.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import Localization
import NoorUI
import SwiftUI

extension View {
    /// Shows the collection rename alert and the errors of `editor`.
    func heldItemEditing(_ editor: HeldItemEditor) -> some View {
        modifier(HeldItemEditingModifier(editor: editor))
    }
}

/// The Edit button of a held item.
struct HeldItemEditButton: View {
    let edit: HeldItemRow.Edit
    let action: @MainActor (HeldItemRow.Edit) async -> Void

    var body: some View {
        Button {
            Task { await action(edit) }
        } label: {
            Text(l("sync.held.edit"))
                .font(.body.weight(.semibold))
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.borderless)
    }
}

private struct HeldItemEditingModifier: ViewModifier {
    @ObservedObject var editor: HeldItemEditor

    func body(content: Content) -> some View {
        content
            .collectionNameAlert(
                l("bookmarks.collections.rename"),
                state: $editor.nameAlert,
                name: $editor.pendingName,
                submit: { await editor.renamePending() }
            )
            .errorAlert(error: $editor.error)
    }
}
#endif
