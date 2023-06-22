//
//  SettingsTabViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-03-03.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Localization
import MessageUI
import NoorUI
import SafariServices
import UIKit

class SettingsTabViewController: TabViewController, SettingsTabPresentable {
    // MARK: Internal

    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: lAndroid("menu_settings"),
            image: NoorImage.settings.uiImage,
            selectedImage: NoorImage.settingsFilled.uiImage
        )
    }

    func presentShareApp(_ view: UIView) {
        let url = URL(validURL: "https://itunes.apple.com/app/id1118663303")
        let appName = "Quran - by Quran.com - قرآن"

        ShareController.share(
            textLines: [appName, url],
            sourceView: view,
            sourceRect: view.bounds,
            sourceViewController: self,
            handler: nil
        )
    }

    func presentContactUs() {
        let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
        let device = Self.unameMachine
        let iosVersion = UIDevice.current.systemVersion
        let appDetails = [appVersion, device, iosVersion].joined(separator: "|")
        let decodedAppDetails = appDetails.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let urlString = "https://docs.google.com/forms/d/e/1FAIpQLSduPT6DFmx2KGOS0I7khpww4FuvLGEDBlzKBhdw6dgIPU_6sg/viewform?entry.1440014003="
            + decodedAppDetails
        let url = URL(string: urlString)!
        let vc = SFSafariViewController(url: url)
        present(vc, animated: true)
    }

    // MARK: Private

    private static var unameMachine: String {
        var utsnameInstance = utsname()
        uname(&utsnameInstance)
        let optionalString: String? = withUnsafePointer(to: &utsnameInstance.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(validatingUTF8: $0) }
        }
        return optionalString ?? "Unknown"
    }
}

extension SettingsTabViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
