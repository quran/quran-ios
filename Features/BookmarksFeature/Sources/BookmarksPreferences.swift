#if QURAN_SYNC
//
//  BookmarksPreferences.swift
//

import Preferences

struct BookmarksPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = BookmarksPreferences()

    @Preference(collectionsIntroRetired)
    var isCollectionsIntroRetired: Bool

    /// Whether the user retired the "Your page bookmarks are here" card.
    @Preference(oldPageBookmarksTipDismissedKey)
    var isOldPageBookmarksTipDismissed: Bool

    static func reset() {
        Preferences.shared.removeValueForKey(oldPageBookmarksTipDismissedKey)
    }

    // MARK: Private

    private static let collectionsIntroRetired = PreferenceKey<Bool>(
        key: "com.quran.bookmarks.collections-intro-retired",
        defaultValue: false
    )

    private static let oldPageBookmarksTipDismissedKey = PreferenceKey<Bool>(
        key: "com.quran.bookmarks.old-page-bookmarks-tip-dismissed",
        defaultValue: false
    )
}
#endif
