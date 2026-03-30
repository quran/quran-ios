//
//  CompletionsBuilder.swift
//
//
//  Created by Selim on 29.03.2026.
//

import AppDependencies
import CompletionService
import FeaturesSupport
import UIKit

@MainActor
public struct CompletionsBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let service = CompletionService(
            persistence: container.completionPersistence,
            pageBookmarkPersistence: container.pageBookmarkPersistence
        )
        let viewModel = CompletionsViewModel(
            service: service,
            navigateTo: { [weak listener] page in
                listener?.navigateTo(page: page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        let viewController = CompletionsViewController(viewModel: viewModel)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
