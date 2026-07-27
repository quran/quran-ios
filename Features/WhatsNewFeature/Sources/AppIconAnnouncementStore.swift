//
//  AppIconAnnouncementStore.swift
//  Quran
//
//

import Preferences

final class AppIconAnnouncementStore {
    @Preference(hasSeenAnnouncementKey)
    var hasSeenAnnouncement: Bool

    private static let hasSeenAnnouncementKey = PreferenceKey<Bool>(
        key: "new-icon-announcement.seen",
        defaultValue: false
    )
}
