#if QURAN_SYNC
import Foundation
import Preferences

struct BookmarkCollectionsPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = BookmarkCollectionsPreferences()

    @Preference(syncBannerDismissed)
    var isSyncBannerDismissed: Bool

    // MARK: Private

    private static let syncBannerDismissed = PreferenceKey<Bool>(
        key: "com.quran.sync.bookmarks.banner-dismissed",
        defaultValue: false
    )
}
#endif
