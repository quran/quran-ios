//
//  AppVersionUpdater.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/2/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Preferences
import SystemDependencies

public typealias AppVersion = String

public enum LaunchVersionUpdate {
    case sameVersion(version: AppVersion)
    case firstLaunch(version: AppVersion)
    case update(from: AppVersion, to: AppVersion)
}

struct AppVersionPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = AppVersionPreferences()

    @Preference(appVersion)
    var appVersion: String?

    static func reset() {
        Preferences.shared.removeValueForKey(appVersion)
    }

    // MARK: Private

    private static let appVersion = PreferenceKey<String?>(key: "appVersion", defaultValue: nil)
}

struct AppVersionUpdater {
    // MARK: Lifecycle

    init(bundle: SystemBundle) {
        self.bundle = bundle
    }

    // MARK: Internal

    func launchVersion() -> LaunchVersionUpdate {
        let current = current
        let previous = preferences.appVersion

        if let previous {
            if previous == current {
                return .sameVersion(version: current)
            } else {
                return .update(from: previous, to: current)
            }
        } else {
            return .firstLaunch(version: current)
        }
    }

    /// eventually we should update the app version
    func commitUpdates() {
        preferences.appVersion = current
    }

    // MARK: Private

    private let bundle: SystemBundle
    private let preferences = AppVersionPreferences.shared

    private var current: String {
        guard let version = bundle.infoValue(forKey: "CFBundleShortVersionString") as? String else {
            fatalError("CFBundleShortVersionString should be set in your main bundle.")
        }
        return version
    }
}
