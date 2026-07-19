//
//  TranslationsViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-07.
//

import Localization
import SwiftUI
import UIKit
import UIx

final class TranslationsViewController: UIHostingController<TranslationsListView> {
    // MARK: Lifecycle

    init(viewModel: TranslationsListViewModel) {
        self.viewModel = viewModel
        super.init(rootView: TranslationsListView(viewModel: viewModel))

        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var editController: EditController?
    private let viewModel: TranslationsListViewModel

    private var currentEditMode: EditMode? {
        if viewModel.downloadedTranslations.isEmpty && viewModel.selectedTranslations.isEmpty {
            return nil
        }
        return viewModel.editMode
    }

    private func initialize() {
        title = lAndroid("prefs_translations")

        editController = EditController(
            navigationItem: navigationItem,
            reload: viewModel.objectWillChange.eraseToAnyPublisher(),
            editMode: Binding(
                get: { [weak self] in self?.currentEditMode },
                set: { [weak self] value in self?.viewModel.editMode = value ?? .inactive }
            )
        )
    }
}
