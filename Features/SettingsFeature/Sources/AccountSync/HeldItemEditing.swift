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
    /// The item's title, which VoiceOver reads with Edit.
    let title: MultipartText
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
        .accessibilityLabel(l("sync.held.edit") + l("list.separator.comma") + title.accessibilityText)
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
            .alert(
                l("bookmarks.collections.rename"),
                isPresented: Binding(
                    get: { editor.renamingReadingBookmark != nil },
                    set: { isPresented in
                        if !isPresented {
                            editor.renamingReadingBookmark = nil
                        }
                    }
                ),
                presenting: editor.renamingReadingBookmark
            ) { slot in
                TextField(lFormat("bookmarks.reading.name.accessibility-label", slot.displayName), text: $editor.pendingName)
                Button(lAndroid("cancel"), role: .cancel) {}
                Button(l("bookmarks.collections.rename")) {
                    Task { await editor.renameReadingBookmark(in: slot) }
                }
            }
            .errorAlert(error: $editor.error)
    }
}
#endif
