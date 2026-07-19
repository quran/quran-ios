//
//  MoreMenuController.swift
//
//
//  Created by Afifi, Mohamed on 9/6/21.
//

import NoorUI
import SwiftUI
import UIKit

class MoreMenuController: UIHostingController<MoreMenuView> {
    // MARK: Lifecycle

    init(viewModel: MoreMenuViewModel) {
        self.viewModel = viewModel
        super.init(rootView: .init(store: viewModel))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = nil
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)
        preferredContentSize = container.preferredContentSize
    }

    // MARK: Private

    private let viewModel: MoreMenuViewModel
}
