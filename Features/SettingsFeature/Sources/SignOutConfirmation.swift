#if QURAN_SYNC
import Localization
import MobileSync
import SwiftUI

/// What the sign-out confirmation says: that everything synced, or what signing out loses.
struct SignOutWarning: Equatable {
    // MARK: Lifecycle

    /// - Parameter unsynced: The items that haven't synced, or `nil` when they couldn't be read.
    init(unsynced: MobileSyncUnsyncedItemCounts?) {
        guard let unsynced else {
            message = l("sync.sign-out.unsynced-unknown")
            offersReview = true
            return
        }
        guard unsynced.pending + unsynced.held > 0 else {
            message = l("setting.quran_account.sign_out.confirmation.message")
            offersReview = false
            return
        }
        let counts = [
            unsynced.pending > 0 ? lFormat("sync.sign-out.pending", unsynced.pending) : nil,
            unsynced.held > 0 ? lFormat("sync.sign-out.held", unsynced.held) : nil,
        ]
        message = (counts.compactMap { $0 } + [l("sync.sign-out.unsynced-lost")]).joined(separator: "\n")
        offersReview = true
    }

    // MARK: Internal

    let message: String
    /// Whether it offers Review, to look at what hasn't synced instead of signing out, in place of Cancel.
    let offersReview: Bool
}

extension View {
    /// Confirms sign-out, which removes the synced bookmarks and notes from this device and loses the changes that
    /// haven't synced yet.
    @MainActor
    func signOutConfirmation(
        isPresented: Binding<Bool>,
        warning: SignOutWarning,
        review: @escaping @MainActor () -> Void,
        signOut: @escaping @MainActor () async -> Void
    ) -> some View {
        alert(
            l("setting.quran_account.sign_out.confirmation.title"),
            isPresented: isPresented
        ) {
            if warning.offersReview {
                Button(l("sync.sign-out.review"), role: .cancel) {
                    review()
                }
            } else {
                Button(lAndroid("cancel"), role: .cancel) {}
            }
            Button(l("setting.quran_account.sign_out"), role: .destructive) {
                Task { await signOut() }
            }
        } message: {
            Text(warning.message)
        }
    }
}
#endif
