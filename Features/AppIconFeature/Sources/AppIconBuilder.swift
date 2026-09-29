//
//  AppIconBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import AppDependencies
import Localization
import SwiftUI
import UIKit

@MainActor
public struct AppIconBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(source: AppIconListSource) -> UIViewController {
        let viewModel = AppIconListViewModel(
            appIconService: container.appIconService(),
            analytics: container.analytics,
            source: source
        )
        let view = AppIconListView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = l("app_icon.title")
        viewController.navigationItem.largeTitleDisplayMode = .never
        return viewController
    }

    // MARK: Private

    private let container: AppDependencies
}
