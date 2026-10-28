#if QURAN_SYNC
import Localization
import MobileSync
import SwiftUI

/// What the sign-out confirmation says: that everything synced, or what signing out loses.
struct SignOutWarning: Equatable {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - unsynced: The items that haven't synced, or `nil` when they couldn't be read.
    ///   - activity: The live held items, which say how many of the held ones the user must fix, as the Not syncing
    ///     list shows them; the rest wait on those.
    init(unsynced: MobileSyncUnsyncedItemCounts?, activity: SyncActivity) {
        showsHeldItems = !activity.blockingItems.isEmpty
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
        message = ([Self.pending(unsynced), Self.held(unsynced, activity: activity)].compactMap { $0 }
            + [l("sync.sign-out.unsynced-lost")]).joined(separator: "\n")
        offersReview = true
    }

    // MARK: Internal

    let message: String
    /// Whether it offers Review, to look at what hasn't synced instead of signing out, in place of Cancel.
    let offersReview: Bool
    /// Whether Review shows the Not syncing items, which only the held items the user must fix appear in.
    let showsHeldItems: Bool

    // MARK: Private

    private static func pending(_ unsynced: MobileSyncUnsyncedItemCounts) -> String? {
        unsynced.pending > 0 ? lFormat("sync.sign-out.pending", unsynced.pending) : nil
    }

    private static func held(_ unsynced: MobileSyncUnsyncedItemCounts, activity: SyncActivity) -> String? {
        guard unsynced.held > 0 else {
            return nil
        }
        // MobileSync counts the items waiting on a held one as held too. Before the live list arrives, all count.
        let blocking = activity.blockingItems.count
        let toFix = blocking > 0 ? min(blocking, unsynced.held) : unsynced.held
        let waiting = unsynced.held - toFix
        return waiting > 0 ? lFormat("sync.sign-out.held-waiting", toFix, waiting) : lFormat("sync.sign-out.held", toFix)
    }
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
