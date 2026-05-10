#if QURAN_SYNC
    //
    //  ReadingBookmarkPreferences.swift
    //

    import Preferences

    struct ReadingBookmarkPreferences {
        // MARK: Lifecycle

        private init() {}

        // MARK: Internal

        static let shared = ReadingBookmarkPreferences()

        @Preference(educationShown)
        var isEducationShown: Bool

        // MARK: Private

        private static let educationShown = PreferenceKey<Bool>(
            key: "com.quran.sync.reading-bookmark.education-shown",
            defaultValue: false
        )
    }
#endif
