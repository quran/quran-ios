//
//  ReciterListBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import UIKit

public struct ReciterListBuilder {
    // MARK: Lifecycle

    public init() {}

    // MARK: Public

    @MainActor
    public func build(withListener listener: ReciterListListener) -> UIViewController {
        let viewModel = ReciterListViewModel()
        let viewController = ReciterTableViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
}
