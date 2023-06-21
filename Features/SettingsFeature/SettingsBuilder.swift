//
//  SettingsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import UIKit

@MainActor
public struct SettingsBuilder {
    // MARK: Lifecycle

    public init() {
    }

    // MARK: Public

    public func build(title: String, settings: [SettingSection]) -> UIViewController {
        let viewController = SettingsViewController(settings: settings)
        viewController.title = title
        return viewController
    }
}
