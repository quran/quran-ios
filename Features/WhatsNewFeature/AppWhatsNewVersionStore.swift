//
//  AppWhatsNewVersionStore.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Foundation
import Preferences
import WhatsNewKit

/// The InMemoryWhatsNewVersionStore
final class AppWhatsNewVersionStore: WhatsNewVersionStore {
    // MARK: Public

    public func has(version: WhatsNew.Version) -> Bool {
        false
    }

    // MARK: Internal

    @Preference(whatsNewVersion)
    var lastSeenVersion: String?

    func set(version: WhatsNew.Version) {
        lastSeenVersion = version.description
    }

    // MARK: Private

    private static let whatsNewVersion = PreferenceKey<String?>(key: "whats-new.seen-version", defaultValue: nil)
}
