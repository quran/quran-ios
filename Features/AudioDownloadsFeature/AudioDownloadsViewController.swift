//
//  AudioDownloadsViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-06-30.
//

import Combine
import Localization
import SwiftUI
import UIx

final class AudioDownloadsViewController: UIHostingController<AudioDownloadsView> {
    // MARK: Lifecycle

    init(viewModel: AudioDownloadsViewModel) {
        self.viewModel = viewModel
        super.init(rootView: AudioDownloadsView(viewModel: viewModel))

        initialize()
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Private

    private var editController: EditController?
    private let viewModel: AudioDownloadsViewModel

    private var currentEditMode: EditMode? {
        if viewModel.items.allSatisfy({ !$0.canDelete }) {
            return nil
        }
        return viewModel.editMode
    }

    private func initialize() {
        title = lAndroid("audio_manager")

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
