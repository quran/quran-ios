//
//  AnalyticsSettingsPreferences.swift
//
//
//  Created by Mohamed Afifi on 2026-11-17.
//

import Foundation
import Preferences

final class AnalyticsSettingsPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = AnalyticsSettingsPreferences()

    /// When the settings snapshot was last logged, so it's logged at most once a day.
    @Preference(lastSnapshotDate) var lastSnapshotDate: Date?

    // MARK: Private

    private static let lastSnapshotDate = PreferenceKey<Date?>(
        key: "com.quran.analytics.settings.last-snapshot-date",
        defaultValue: nil
    )
}
