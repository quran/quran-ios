#if QURAN_SYNC
import Analytics

public enum QuranSyncAuthenticationSource: String, Sendable {
    case bookmarks
    case notes
    case settings
}

public extension AnalyticsLibrary {
    func quranSyncSignIn(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignIn", value: source.rawValue)
    }

    func quranSyncSignOut(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignOut", value: source.rawValue)
    }

    func quranSyncSignInBannerDismissed(from source: QuranSyncAuthenticationSource) {
        logEvent("QuranSyncSignInBannerDismissed", value: source.rawValue)
    }
}
#endif
