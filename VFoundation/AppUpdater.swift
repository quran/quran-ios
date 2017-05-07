//
//  AppUpdater.swift
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

extension PersistenceKeyBase {
    public static let appVersion = PersistenceKey<String?>(key: "appVersion", defaultValue: nil)
}

public struct AppUpdater {
    public typealias AppVersion = String

    public enum VersionUpdate {
        case sameVersion(version: AppVersion)
        case firstLaunch(version: AppVersion)
        case update(from: AppVersion, to: AppVersion)
    }

    public let persistence = UserDefaultsSimplePersistence(userDefaults: .standard)

    public init() { }

    public func updated() -> VersionUpdate {
        let current: String = cast(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString"))
        let previous = persistence.valueForKey(.appVersion)

        // eventually we should update the app version
        defer {
            persistence.setValue(current, forKey: PersistenceKeyBase.appVersion)
        }

        if let previous = previous {
            if previous == current {
                return .sameVersion(version: current)
            } else {
                return .update(from: previous, to: current)
            }
        } else {
            return .firstLaunch(version: current)
        }
    }
}
