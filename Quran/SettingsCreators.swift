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
import MessageUI

protocol SettingsCreators {
    func createSettingsItems() -> [Setting]
    var parentController: SettingsViewController? { get set }
}

class NavigationSettingsCreators: SettingsCreators {
    weak var parentController: SettingsViewController?

    private let translationsCreator: AnyCreator<Void, UIViewController>
    private let audioDownloadsCreator: AnyCreator<Void, UIViewController>

    init(translationsCreator: AnyCreator<Void, UIViewController>, audioDownloadsCreator: AnyCreator<Void, UIViewController>) {
        self.translationsCreator = translationsCreator
        self.audioDownloadsCreator = audioDownloadsCreator
    }

    func createSettingsItems() -> [Setting] {
        let translation = SettingItem(name: lAndroid("prefs_translations"), image: #imageLiteral(resourceName: "globe-25")) { [weak self] (vc, _) in
            if let controller = self?.translationsCreator.create(()) {
                controller.hidesBottomBarWhenPushed = true
                vc.navigationController?.pushViewController(controller, animated: true)
            }
        }
        let audio = SettingItem(name: lAndroid("audio_manager"), image: #imageLiteral(resourceName: "download-25")) { [weak self] (vc, _) in
            if let controller = self?.audioDownloadsCreator.create(()) {
                controller.hidesBottomBarWhenPushed = true
                vc.navigationController?.pushViewController(controller, animated: true)
            }
        }
        let review = SettingItem(name: l("write_review"), image: #imageLiteral(resourceName: "star_border")) { (_, _) in
            guard let url = URL(string: "itms-apps://itunes.apple.com/app/id1118663303?action=write-review") else {
                return
            }

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
            Analytics.shared.review(automatic: false)
        }
        let shareApp = SettingItem(name: l("share_app"), image: #imageLiteral(resourceName: "share")) { (vc, cell) in
            guard let url = URL(string: "https://itunes.apple.com/app/id1118663303") else {
                return
            }
            let appName = "Quran - by Quran.com - قرآن"

            ShareController.share(textLines: [appName, url], sourceView: cell, sourceRect: cell.bounds, sourceViewController: vc, handler: nil)
            Analytics.shared.shareApp()
        }
        let email = SettingItem(name: l("contact_us"), image: #imageLiteral(resourceName: "email-outline")) { (vc, _) in
            if MFMailComposeViewController.canSendMail() {
                let mail = MFMailComposeViewController()
                mail.navigationBar.tintColor = .white
                mail.mailComposeDelegate = self.parentController
                mail.setToRecipients(["ios@quran.com"])
                mail.setSubject("Feedback about Quran for iOS App")
                vc.present(mail, animated: true, completion: nil)
            }
        }
        return [EmptySetting(), ThemeSetting(), EmptySetting(), translation, audio, EmptySetting(), shareApp, review, email]
    }
}
