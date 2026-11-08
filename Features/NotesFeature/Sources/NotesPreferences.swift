#if QURAN_SYNC
//
//  NotesPreferences.swift
//

import Preferences

struct NotesPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = NotesPreferences()

    /// Whether the user retired the "Highlights now live in Bookmarks" card.
    @Preference(highlightsTipDismissedKey)
    var isHighlightsTipDismissed: Bool

    static func reset() {
        Preferences.shared.removeValueForKey(highlightsTipDismissedKey)
    }

    // MARK: Private

    private static let highlightsTipDismissedKey = PreferenceKey<Bool>(
        key: "com.quran.notes.highlights-tip-dismissed",
        defaultValue: false
    )
}
#endif
