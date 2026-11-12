//
//  AppWhatsNewVersionStore.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Preferences

final class AppWhatsNewVersionStore {
    // MARK: Internal

    /// The last marketing version the user saw, such as "3.0.1".
    @Preference(whatsNewVersion)
    var lastSeenVersion: String?

    /// The TestFlight build (`CFBundleVersion`) the user saw ``lastSeenVersion`` on.
    /// `nil` outside TestFlight, where each marketing version shows once.
    @Preference(whatsNewBuild)
    var lastSeenBuild: String?

    static func reset() {
        Preferences.shared.removeValueForKey(whatsNewVersion)
        Preferences.shared.removeValueForKey(whatsNewBuild)
    }

    // MARK: Private

    private static let whatsNewVersion = PreferenceKey<String?>(key: "whats-new.seen-version", defaultValue: nil)
    private static let whatsNewBuild = PreferenceKey<String?>(key: "whats-new.seen-build", defaultValue: nil)
}
