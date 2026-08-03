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
            delete: {
                guard let item = item.wrappedValue else {
                    return
                }
                await delete(item)
            }
        )
    }

    @MainActor
    func collectionDeleteConfirmation(
        isPresented: Binding<Bool>,
        delete: @escaping @MainActor () async -> Void
    ) -> some View {
        alert(
            l("bookmarks.collections.delete.confirmation.title"),
            isPresented: isPresented
        ) {
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("button.delete"), role: .destructive) {
                Task { await delete() }
            }
        } message: {
            Text(l("bookmarks.collections.delete.confirmation.message"))
        }
    }
}
#endif
