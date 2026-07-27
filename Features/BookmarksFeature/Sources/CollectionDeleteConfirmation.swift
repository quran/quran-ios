#if QURAN_SYNC
import Localization
import SwiftUI

extension View {
    @MainActor
    func collectionDeleteConfirmation<Item>(
        item: Binding<Item?>,
        delete: @escaping @MainActor (Item) async -> Void
    ) -> some View {
        alert(
            l("bookmarks.collections.delete.confirmation.title"),
            isPresented: Binding(
                get: { item.wrappedValue != nil },
                set: { isPresented in
                    if !isPresented {
                        item.wrappedValue = nil
                    }
                }
            ),
            presenting: item.wrappedValue
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
