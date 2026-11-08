#if QURAN_SYNC
import Preferences

/// Whether the reading bookmark toasts have already explained saving and moving on this device.
struct ReadingBookmarkExplanationPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = ReadingBookmarkExplanationPreferences()

    @Preference(hasExplainedSaveKey)
    var hasExplainedSave: Bool

    @Preference(hasExplainedMoveKey)
    var hasExplainedMove: Bool

    // MARK: Private

    private static let hasExplainedSaveKey = PreferenceKey<Bool>(
        key: "com.quran.reading-bookmarks.save-explained",
        defaultValue: false
    )

    private static let hasExplainedMoveKey = PreferenceKey<Bool>(
        key: "com.quran.reading-bookmarks.move-explained",
        defaultValue: false
    )
}
#endif
