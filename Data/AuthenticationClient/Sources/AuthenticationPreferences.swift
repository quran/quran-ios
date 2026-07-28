#if QURAN_SYNC
import Preferences

public struct AuthenticationPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = AuthenticationPreferences()

    @Preference(collectionsSyncBannerDismissed)
    public var isCollectionsSyncBannerDismissed: Bool

    @Preference(notesSyncBannerDismissed)
    public var isNotesSyncBannerDismissed: Bool

    // MARK: Private

    private static let collectionsSyncBannerDismissed = PreferenceKey<Bool>(
        key: "com.quran.sync.bookmarks.banner-dismissed",
        defaultValue: false
    )

    private static let notesSyncBannerDismissed = PreferenceKey<Bool>(
        key: "com.quran.sync.notes.banner-dismissed",
        defaultValue: false
    )
}
#endif
