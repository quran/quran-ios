//
//  AudioDownloadsViewController.swift
//
//
//  Created by Mohamed Afifi on 2023-06-30.
//

import Combine
import Localization
import SwiftUI

final class AudioDownloadsViewController: UIHostingController<AudioDownloadsView> {
    private enum EditButtonState {
        case none
        case edit
        case done
    }

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

    private let viewModel: AudioDownloadsViewModel
    private var cancellables: Set<AnyCancellable> = []

    private var editButtonState = EditButtonState.none {
        didSet {
            if oldValue != editButtonState {
                updateEditButton()
            }
        }
    }

    private var editButton: UIBarButtonItem? {
        switch editButtonState {
        case .none:
            return nil
        case .edit:
            return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEditing))
        case .done:
            return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditing))
        }
    }

    private func initialize() {
        title = lAndroid("audio_manager")

        viewModel.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                // Getting viewModel values after the change since we used recieve in the pipeline.
                self?.updateEditButtonIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func updateEditButtonIfNeeded() {
        editButtonState = calculateEditButtonState()
    }

    private func updateEditButton() {
        navigationItem.setRightBarButton(editButton, animated: true)
    }

    private func calculateEditButtonState() -> EditButtonState {
        if viewModel.items.allSatisfy({ !$0.canDelete }) {
            return .none
        }
        return viewModel.editMode == .active ? .done : .edit
    }

    @objc
    private func startEditing() {
        withAnimation {
            viewModel.editMode = .active
        }
    }

    @objc
    private func endEditing() {
        withAnimation {
            viewModel.editMode = .inactive
        }
    }
}
