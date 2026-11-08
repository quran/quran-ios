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

    // MARK: Private

    private static let collectionsIntroRetired = PreferenceKey<Bool>(
        key: "com.quran.bookmarks.collections-intro-retired",
        defaultValue: false
    )
}
#endif
