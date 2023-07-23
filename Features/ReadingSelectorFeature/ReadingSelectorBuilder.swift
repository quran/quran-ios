//
//  ReadingSelectorBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 2023-02-14.
//  Copyright © 2023 Quran.com. All rights reserved.
//

import AppDependencies
import UIKit

@MainActor
public struct ReadingSelectorBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build() -> UIViewController {
        let viewModel = ReadingSelectorViewModel(
            resources: container.readingResources
        )
        return ReadingSelectorViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies
}
