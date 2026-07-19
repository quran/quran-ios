//
//  MigrationViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import NoorUI
import SwiftUI
import UIKit

@MainActor
public final class MigrationViewController: BaseViewController {
    // MARK: Lifecycle

    public init() {
        let viewModel = MigrationViewModel(titles: [])
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)

        let viewController = UIHostingController(rootView: MigrationView(viewModel: viewModel))
        addFullScreenChild(viewController)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public func setTitles(_ titles: Set<String>) {
        viewModel.setTitles(titles)
    }

    // MARK: Private

    private let viewModel: MigrationViewModel
}
