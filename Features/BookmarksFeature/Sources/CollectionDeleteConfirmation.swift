#if QURAN_SYNC
import Localization
import SwiftUI

extension View {
    @MainActor
    func collectionDeleteConfirmation<Item>(
        item: Binding<Item?>,
        delete: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        collectionDeleteConfirmation(
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        item.wrappedValue = nil
                    }
                }
            ),
            presenting: item.wrappedValue,
            delete: delete
        )
    }

    @MainActor
    func collectionDeleteConfirmation(
        isPresented: Binding<Bool>,
        delete: @escaping @MainActor () async -> Void
    ) -> some View {
        collectionDeleteConfirmation(
            isPresented: isPresented,
            presenting: (),
            delete: { _ in await delete() }
        )
    }

    /// Hands the presented item to the Delete action, because SwiftUI dismisses the alert,
    /// clearing a binding-derived item, before the action's task runs.
    @MainActor
    private func collectionDeleteConfirmation<Item>(
        isPresented: Binding<Bool>,
        presenting item: Item?,
        delete: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        alert(
            l("bookmarks.collections.delete.confirmation.title"),
            isPresented: isPresented,
            presenting: item
        ) { item in
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("button.delete"), role: .destructive) {
                Task { await delete(item) }
            }
        } message: { _ in
            Text(l("bookmarks.collections.delete.confirmation.message"))
        }
    }
}
#endif
