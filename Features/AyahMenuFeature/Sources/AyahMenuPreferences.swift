#if QURAN_SYNC
import Preferences

struct AyahMenuPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = AyahMenuPreferences()

    @Preference(readingBookmarkNewBadgeViews)
    var readingBookmarkNewBadgeViews: Int

    @Preference(readingBookmarkNewBadgeRetired)
    var isReadingBookmarkNewBadgeRetired: Bool

    // MARK: Private

    private static let readingBookmarkNewBadgeViews = PreferenceKey<Int>(
        key: "com.quran.ayah-menu.reading-bookmark.new-badge.views",
        defaultValue: 0
    )

    private static let readingBookmarkNewBadgeRetired = PreferenceKey<Bool>(
        key: "com.quran.ayah-menu.reading-bookmark.new-badge.retired",
        defaultValue: false
    )
}
#endif
