#if QURAN_SYNC
//
//  SyncSignInNudgePreferences.swift
//

import Foundation
import Preferences

public final class SyncSignInNudgePreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = SyncSignInNudgePreferences()

    /// Forgets that the reminder ever showed or stopped.
    public func reset() {
        Preferences.shared.removeValueForKey(Self.showCount)
        Preferences.shared.removeValueForKey(Self.lastShownDate)
        Preferences.shared.removeValueForKey(Self.stopped)
    }

    // MARK: Internal

    /// How many times the reminder showed after saving a note or a collection.
    @Preference(showCount) var showCount: Int

    @Preference(lastShownDate) var lastShownDate: Date?

    /// Set once the user taps the reminder's Sign In, dismisses it, or signs in, so it never shows again.
    @Preference(stopped) var isStopped: Bool

    // MARK: Private

    private static let showCount = PreferenceKey<Int>(
        key: "com.quran.sync.sign-in-nudge.show-count",
        defaultValue: 0
    )

    private static let lastShownDate = PreferenceKey<Date?>(
        key: "com.quran.sync.sign-in-nudge.last-shown-date",
        defaultValue: nil
    )

    private static let stopped = PreferenceKey<Bool>(
        key: "com.quran.sync.sign-in-nudge.stopped",
        defaultValue: false
    )
}
#endif
