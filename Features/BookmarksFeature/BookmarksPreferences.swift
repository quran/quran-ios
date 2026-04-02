import Foundation
import Preferences

struct BookmarksPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = BookmarksPreferences()

    @Preference(syncBannerDismissed)
    var isSyncBannerDismissed: Bool

    // MARK: Private

    private static let syncBannerDismissed = PreferenceKey<Bool>(
        key: "com.quran.sync.bookmarks.banner-dismissed",
        defaultValue: false
    )
}
