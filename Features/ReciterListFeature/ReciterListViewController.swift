//
//  ReciterListViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-25.
//

import SwiftUI
import UIx

final class ReciterListViewController: UIHostingController<ReciterListView>, StackableViewController {
    // MARK: Lifecycle

    init(viewModel: ReciterListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: ReciterListView(viewModel: viewModel))
        rotateToPortraitIfPhone()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    // MARK: Private

    private let viewModel: ReciterListViewModel
}
