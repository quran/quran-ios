//
//  CompletionsViewController.swift
//
//
//  Created by Selim on 29.03.2026.
//

import Localization
import NoorUI
import SwiftUI
import UIx

final class CompletionsViewController: UIHostingController<CompletionsView> {
    // MARK: Lifecycle

    init(viewModel: CompletionsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: CompletionsView(viewModel: viewModel))
        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private let viewModel: CompletionsViewModel

    private func initialize() {
        title = "Completions"
        addCloudSyncInfo()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTapped)
        )
    }

    @objc
    private func addTapped() {
        viewModel.isShowingNewCompletion = true
    }
}
