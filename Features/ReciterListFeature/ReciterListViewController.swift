//
//  ReciterListViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-25.
//

import Localization
import SwiftUI
import UIx

final class ReciterListViewController: UIHostingController<ReciterListView> {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        title = l("reciters.title")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(cancelButtonTapped))
    }

    // MARK: Private

    private let viewModel: ReciterListViewModel

    @objc
    private func cancelButtonTapped() {
        viewModel.dismissRecitersList()
    }
}
