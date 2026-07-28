//
//  AppWhatsNew.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization

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

    var localizedTitle: String {
        l(title)
    }

    var localizedDetails: [String] {
        subtitleText
            .components(separatedBy: .newlines)
            .map { detail in
                detail.hasPrefix("* ") ? String(detail.dropFirst(2)) : detail
            }
            .filter { !$0.isEmpty }
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
