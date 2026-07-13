#if QURAN_SYNC
import Foundation
import Preferences

struct BookmarkCollectionsLandingPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = BookmarkCollectionsLandingPreferences()

    @Preference(syncBannerDismissed)
    var isSyncBannerDismissed: Bool

    // MARK: Private

    private static let syncBannerDismissed = PreferenceKey<Bool>(
        key: "com.quran.sync.bookmarks.banner-dismissed",
        defaultValue: false
    )
}
#endif
