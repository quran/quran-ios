//
//  EditController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-07.
//

import Combine
import SwiftUI

@MainActor
public final class EditController {
    // MARK: Lifecycle

    public init(
        navigationItem: UINavigationItem,
        reload: AnyPublisher<Void, Never>,
        editMode: Binding<EditMode?>,
        customItems: [UIBarButtonItem] = []
    ) {
        self.navigationItem = navigationItem
        self.customItems = customItems
        _editMode = editMode

        reload
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateEditButtonStateIfNeeded()
            }
            .store(in: &cancellables)
    }

    // MARK: Private

    private let navigationItem: UINavigationItem
    private var customItems: [UIBarButtonItem]
    @Binding private var editMode: EditMode?
    private var cancellables: Set<AnyCancellable> = []

    private var buttonEditModeState: EditMode? {
        didSet {
            if oldValue != buttonEditModeState {
                updateEditButton()
            }
        }
    }

    private var editButton: UIBarButtonItem? {
        switch buttonEditModeState {
        case .none:
            return nil
        case .some(let editMode):
            if editMode.isEditing {
                return UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditing))
            } else {
                return UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(startEditing))
            }
        }
    }

    private func updateEditButtonStateIfNeeded() {
        buttonEditModeState = editMode
    }

    private func updateEditButton() {
        if let editButton = editButton {
            navigationItem.setRightBarButtonItems(customItems + [editButton], animated: true)
        } else {
            navigationItem.setRightBarButtonItems(customItems, animated: true)
        }
    }

    @objc
    private func startEditing() {
        withAnimation {
            editMode = .active
        }
    }

    @objc
    private func endEditing() {
        withAnimation {
            editMode = .inactive
        }
    }
}
