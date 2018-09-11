//
//  UpdateHandler.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/10/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

protocol VersionUpdater {
    func execute(update: AppUpdater.VersionUpdate)
}

class UpdateHandler {

    private var updaters: [AppUpdater.AppVersion: [VersionUpdater]] = [:]

    func add(updater: VersionUpdater, for version: AppUpdater.AppVersion) {
        var array = updaters[version] ?? []
        array.append(updater)
        updaters[version] = array
    }

    func onUpdate(versionUpdate: AppUpdater.VersionUpdate) {
        switch versionUpdate {
        case .update(_, to: let toVersion):
            for updater in updaters[toVersion] ?? [] {
                updater.execute(update: versionUpdate)
            }
        default:
            break
        }
    }
}
