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
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }

    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        // Rotating needs the window, which the controller only has once it appears.
        rotateToPortraitIfPhone()
    }

    // MARK: Private

    private let viewModel: ReciterListViewModel
}
