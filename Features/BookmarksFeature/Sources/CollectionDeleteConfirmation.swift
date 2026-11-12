#if QURAN_SYNC
import Localization
import SwiftUI

extension View {
    @MainActor
    func collectionDeleteConfirmation<Item>(
        item: Binding<Item?>,
        delete: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        destructiveConfirmation(
            l("bookmarks.collections.delete.confirmation.title"),
            actionTitle: l("button.delete"),
            item: item,
            message: { _ in l("bookmarks.collections.delete.confirmation.message") },
            action: delete
        )
    }

    @MainActor
    func collectionDeleteConfirmation(
        isPresented: Binding<Bool>,
        delete: @escaping @MainActor () async -> Void
    ) -> some View {
        destructiveConfirmation(
            l("bookmarks.collections.delete.confirmation.title"),
            actionTitle: l("button.delete"),
            isPresented: isPresented,
            presenting: (),
            message: { _ in l("bookmarks.collections.delete.confirmation.message") },
            action: { _ in await delete() }
        )
    }

    /// Confirms a destructive action on `item`, which presents the alert while it isn't `nil`.
    @MainActor
    func destructiveConfirmation<Item>(
        _ title: String,
        actionTitle: String,
        item: Binding<Item?>,
        message: @escaping (Item) -> String,
        action: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        destructiveConfirmation(
            title,
            actionTitle: actionTitle,
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        item.wrappedValue = nil
                    }
                }
            ),
            presenting: item.wrappedValue,
            message: message,
            action: action
        )
    }

    /// Hands the presented item to the action, because SwiftUI dismisses the alert,
    /// clearing a binding-derived item, before the action's task runs.
    @MainActor
    private func destructiveConfirmation<Item>(
        _ title: String,
        actionTitle: String,
        isPresented: Binding<Bool>,
        presenting item: Item?,
        message: @escaping (Item) -> String,
        action: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        alert(title, isPresented: isPresented, presenting: item) { item in
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(actionTitle, role: .destructive) {
                Task { await action(item) }
            }
        } message: { item in
            Text(message(item))
        }
    }
}
#endif
