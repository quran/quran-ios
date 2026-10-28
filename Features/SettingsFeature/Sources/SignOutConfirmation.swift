#if QURAN_SYNC
import Localization
import SwiftUI

extension View {
    /// Confirms sign-out, which removes the synced bookmarks and notes from this device and loses the changes that
    /// haven't synced yet.
    ///
    /// - Parameter unsyncedCount: How many items haven't synced, or `nil` when it couldn't be read.
    @MainActor
    func signOutConfirmation(
        isPresented: Binding<Bool>,
        unsyncedCount: Int?,
        syncNow: @escaping @MainActor () -> Void,
        signOut: @escaping @MainActor () async -> Void
    ) -> some View {
        alert(
            l("setting.quran_account.sign_out.confirmation.title"),
            isPresented: isPresented
        ) {
            Button(lAndroid("cancel"), role: .cancel) {}
            if unsyncedCount != 0 {
                Button(l("sync.action.sync-now")) {
                    syncNow()
                }
            }
            Button(l("setting.quran_account.sign_out"), role: .destructive) {
                Task { await signOut() }
            }
        } message: {
            Text(signOutConfirmationMessage(unsyncedCount: unsyncedCount))
        }
    }
}

/// Warns about the changes signing out loses, or says that everything synced.
func signOutConfirmationMessage(unsyncedCount: Int?) -> String {
    switch unsyncedCount {
    case 0:
        l("setting.quran_account.sign_out.confirmation.message")
    case let count?:
        lFormat("sync.sign-out.unsynced", count)
    case nil:
        l("sync.sign-out.unsynced-unknown")
    }
}
#endif
