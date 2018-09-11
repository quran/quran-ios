//
//  DarkThemeUpdater.swift
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

import Foundation

class DarkThemeUpdater: VersionUpdater {
    private var persistence: SimplePersistence
    init(persistence: SimplePersistence) {
        self.persistence = persistence
    }

    func execute(update: AppUpdater.VersionUpdate) {
        guard persistence.theme == .light else {
            return
        }

        let alert = UIAlertController(title: l("update.dark-theme.title"), message: l("update.dark-theme.desc"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: l("update.dark-theme.turnOn"), style: .default) { [weak self] _ in
            self?.persistence.theme = .dark
            Analytics.shared.darkThemeUpdate(turnOn: true)
        })
        alert.addAction(UIAlertAction(title: lAndroid("cancel"), style: .cancel) { _ in
            Analytics.shared.darkThemeUpdate(turnOn: false)
        })
        UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
