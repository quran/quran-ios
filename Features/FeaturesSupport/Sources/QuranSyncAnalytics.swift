#if QURAN_SYNC
import Analytics

public enum QuranSyncAuthenticationSource: String, Sendable {
    case settings
    case accountSync = "account_sync"
    case noteSavedToast = "note_saved_toast"
    case collectionCreatedToast = "collection_created_toast"
}

public extension AnalyticsLibrary {
    func quranSyncSignIn(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignIn", value: source.rawValue)
    }

    func quranSyncSignOut(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignOut", value: source.rawValue)
    }

    func quranSyncSignInNudgeShown(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignInNudgeShown", value: source.rawValue)
    }

    func quranSyncSignInNudgeDismissed(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignInNudgeDismissed", value: source.rawValue)
    }
}
#endif
