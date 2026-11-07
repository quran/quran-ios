#if QURAN_SYNC
import Analytics

public enum QuranSyncAuthenticationSource: String, Sendable {
    case settings
    case accountSync = "account_sync"
}

public extension AnalyticsLibrary {
    func quranSyncSignIn(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignIn", value: source.rawValue)
    }

    func quranSyncSignOut(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignOut", value: source.rawValue)
    }
}
#endif
