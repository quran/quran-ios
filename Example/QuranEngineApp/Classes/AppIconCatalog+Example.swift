//
//  AppIconCatalog+Example.swift
//  QuranEngineApp
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Localization
import NoorUI
import UIKit
import UIx

extension AppIconCatalog {
    /// The QuranEngine icons: the amber primary icon and a graphite alternate.
    static let example = AppIconCatalog(sections: [
        Section(
            id: "quran-engine",
            title: l("app_icon.section.icons"),
            previewSize: .large,
            options: [.quranEngine, .graphite]
        ),
    ])
}

extension AppIconOption {
    static let quranEngine = AppIconOption(
        id: "engine-amber",
        alternateIconName: nil,
        name: "QuranEngine",
        previewImageName: "app-icon-engine-amber",
        accent: .amber
    )

    static let graphite = AppIconOption(
        id: "engine-graphite",
        alternateIconName: "AppIcon-Graphite",
        name: l("app_icon.name.graphite"),
        previewImageName: "app-icon-engine-graphite",
        accent: .amber
    )
}

private extension AppIconAccent {
    /// Keep in sync with the `AccentColor` colorset, the global accent.
    static let amber = AppIconAccent(
        light: UIColor(rgb: 0x874C00),
        dark: UIColor(rgb: 0xF5B454),
        onDark: UIColor(rgb: 0x3A2200)
    )
}
