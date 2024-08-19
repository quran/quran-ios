//
//  AppWhatsNew.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import UIKit
import WhatsNewKit

struct AppWhatsNew: Decodable {
    let versions: [WhatsNewVersion]
}

struct WhatsNewVersion: Decodable {
    let version: String
    let items: [WhatsNewItem]
}

struct WhatsNewItem: Decodable {
    // MARK: Internal

    let title: String
    let subtitle: String
    let image: String

    var whatsNewItem: WhatsNew.Item {
        let image: UIImage?
        image = UIImage.symbol(self.image, withConfiguration: UIImage.SymbolConfiguration(weight: .light))
        return .init(
            title: l(title),
            subtitle: subtitleText,
            image: image ?? UIColor.clear.image()
        )
    }

    // MARK: Private

    // Use %%{table}:{key}%% to use a different localization within (e.g. %%Readers:qari_muaiqly_haramain_gapless%%)
    private var subtitleText: String {
        let text = l(subtitle)
        return text.replacingOccurrences(matchingPattern: "\\%\\%(.+?)\\%\\%") { substring in
            localizeText(substring)
        }
    }

    private func localizeText(_ text: String) -> String {
        let components = text.replacingOccurrences(of: "%%", with: "")
            .components(separatedBy: ":")
        return l(components[1], table: Table(rawValue: components[0])!)
    }
}
