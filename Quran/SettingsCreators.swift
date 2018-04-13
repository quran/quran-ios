//
//  SettingsCreators.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/13/17.
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

import Foundation

protocol SettingsCreators {
    func createSettingsItems() -> [Setting]
}

class NavigationSettingsCreators: SettingsCreators {
    private let translationsCreator: AnyCreator<Void, UIViewController>
    private let audioDownloadsCreator: AnyCreator<Void, UIViewController>

    init(translationsCreator: AnyCreator<Void, UIViewController>, audioDownloadsCreator: AnyCreator<Void, UIViewController>) {
        self.translationsCreator = translationsCreator
        self.audioDownloadsCreator = audioDownloadsCreator
    }

    func createSettingsItems() -> [Setting] {
        let translation = Setting(name: NSLocalizedString("prefs_translations", tableName: "Android", comment: ""), image: #imageLiteral(resourceName: "globe-25")) { [weak self] vc in
            if let controller = self?.translationsCreator.create(()) {
                controller.hidesBottomBarWhenPushed = true
                vc.navigationController?.pushViewController(controller, animated: true)
            }
        }
        let audio = Setting(name: NSLocalizedString("audio_manager", tableName: "Android", comment: ""), image: #imageLiteral(resourceName: "download-25")) { [weak self] vc in
            if let controller = self?.audioDownloadsCreator.create(()) {
                controller.hidesBottomBarWhenPushed = true
                vc.navigationController?.pushViewController(controller, animated: true)
            }
        }
        let review = Setting(name: NSLocalizedString("write_review", tableName: "Localizable", comment: ""), image: #imageLiteral(resourceName: "star_border")) { _ in
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id1118663303?action=write-review") else {
                return
            }

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
        return [translation, audio, review]
    }
}
