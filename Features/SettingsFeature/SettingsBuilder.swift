//
//  SettingsBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
import AudioDownloadsFeature
import Localization
import SettingsService
import SwiftUI
import TranslationsFeature
import UIKit

@MainActor
public struct SettingsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(navigationController: UINavigationController) -> UIViewController {
        let viewModel = SettingsRootViewModel(
            analytics: container.analytics,
            reviewService: ReviewService(analytics: container.analytics),
            audioDownloadsBuilder: AudioDownloadsBuilder(container: container),
            translationsListBuilder: TranslationsListBuilder(container: container),
            navigationController: navigationController
        )
        let view = SettingsRootView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = lAndroid("menu_settings")
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
