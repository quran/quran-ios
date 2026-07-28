//
//  AppWhatsNewVersionStore.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Preferences

final class AppWhatsNewVersionStore {
    @Preference(whatsNewVersion)
    var lastSeenVersion: String?

    // MARK: Private

    private static let whatsNewVersion = PreferenceKey<String?>(key: "whats-new.seen-version", defaultValue: nil)
}
