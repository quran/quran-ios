//
//  DiagnosticsBuilder.swift
//
//
//  Created by Mohamed Afifi on 2023-12-10.
//

import AppDependencies
import Localization
import SwiftUI

@MainActor
public struct DiagnosticsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(navigationController: UINavigationController?) -> UIViewController {
        let service = DiagnosticsService(
            logsDirectory: container.logsDirectory,
            databasesDirectory: container.databasesURL
        )
        let viewModel = DiagnosticsViewModel(
            diagnosticsService: service,
            navigationController: navigationController
        )
        let view = DiagnosticsView(viewModel: viewModel)
        let viewController = UIHostingController(rootView: view)
        viewController.title = l("diagnostics.title")
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
