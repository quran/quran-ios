#if QURAN_SYNC
import Localization
import SwiftUI

extension View {
    /// Confirms sign-out, which removes the synced bookmarks and notes from this device.
    ///
    /// `signOut` runs after SwiftUI dismisses the alert, so it must not read state the dismissal clears.
    @MainActor
    func signOutConfirmation(
        isPresented: Binding<Bool>,
        signOut: @escaping @MainActor () async -> Void
    ) -> some View {
        alert(
            l("setting.quran_account.sign_out.confirmation.title"),
            isPresented: isPresented
        ) {
            Button(lAndroid("cancel"), role: .cancel) {}
            Button(l("setting.quran_account.sign_out"), role: .destructive) {
                Task { await signOut() }
            }
        } message: {
            Text(l("setting.quran_account.sign_out.confirmation.message"))
        }
    }
}
#endif
