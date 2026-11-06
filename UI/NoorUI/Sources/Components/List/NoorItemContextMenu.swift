import Localization
import SwiftUI
import UIx

public extension View {
    /// The long-press menu for an item the user can manage: Open, then Rename, Delete and Delete All when the
    /// item has them. Items without any of those, like Home's reading bookmarks, don't get a menu.
    ///
    /// Delete goes through the enclosing `NoorListRows` row's own delete, which also backs its swipe and Edit mode.
    func noorItemContextMenu(
        isEnabled: Bool = true,
        open: @escaping @MainActor () -> Void,
        rename: (@MainActor () -> Void)? = nil,
        deleteAll: (@MainActor () -> Void)? = nil
    ) -> some View {
        modifier(NoorItemContextMenu(isEnabled: isEnabled, open: open, rename: rename, deleteAll: deleteAll))
    }
}

private struct NoorItemContextMenu: ViewModifier {
    let isEnabled: Bool
    let open: @MainActor () -> Void
    let rename: (@MainActor () -> Void)?
    let deleteAll: (@MainActor () -> Void)?

    @Environment(\.noorListRowDelete) private var delete

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if isEnabled, rename != nil || delete != nil || deleteAll != nil {
                    NoorItemMenuItems(open: open, rename: rename, delete: delete, deleteAll: deleteAll)
                }
            }
    }
}

/// The item menu's buttons, shared by the long-press menu and menus that items present themselves.
struct NoorItemMenuItems: View {
    let open: @MainActor () -> Void
    var rename: (@MainActor () -> Void)?
    var delete: (@MainActor () -> Void)?
    let deleteAll: (@MainActor () -> Void)?

    var body: some View {
        Button(action: open) {
            Label { Text(l("bookmarks.reading.open")) } icon: { NoorSystemImage.book.image }
        }
        if let rename {
            Button(action: rename) {
                Label { Text(l("bookmarks.collections.rename")) } icon: { NoorSystemImage.edit.image }
            }
        }
        if let delete {
            Button(role: .destructive, action: delete) {
                Label { Text(l("button.delete")) } icon: { NoorSystemImage.cancel.image }
            }
        }
        if let deleteAll {
            Button(role: .destructive, action: deleteAll) {
                Label { Text(l("bookmarks.delete-all")) } icon: { NoorSystemImage.cancel.image }
            }
        }
    }
}
