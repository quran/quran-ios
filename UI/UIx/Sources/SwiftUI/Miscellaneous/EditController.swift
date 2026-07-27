//
//  EditController.swift
//
//
//  Created by Mohamed Afifi on 2023-07-07.
//

import Combine
import SwiftUI
import UIKit

@MainActor
public final class EditController {
    public typealias ButtonProvider = @MainActor (
        _ editMode: EditMode,
        _ action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem

    // MARK: Lifecycle

    public init(
        navigationItem: UINavigationItem,
        reload: AnyPublisher<Void, Never>,
        editMode: Binding<EditMode?>,
        customItems: [UIBarButtonItem] = [],
        buttonProvider: @escaping ButtonProvider = { editMode, action in
            UIBarButtonItem(
                systemItem: editMode.isEditing ? .done : .edit,
                primaryAction: UIAction { _ in action() }
            )
        }
    ) {
        self.navigationItem = navigationItem
        self.customItems = customItems
        self.buttonProvider = buttonProvider
        _editMode = editMode

        reload
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.updateEditButtonStateIfNeeded()
            }
            .store(in: &cancellables)

        buttonEditModeState = editMode.wrappedValue
        updateEditButton()
    }

    // MARK: Private

    private let navigationItem: UINavigationItem
    private var customItems: [UIBarButtonItem]
    private let buttonProvider: ButtonProvider
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
            return buttonProvider(editMode) { [weak self] in
                withAnimation {
                    self?.editMode = editMode.isEditing ? .inactive : .active
                }
            }
        }
    }

    private func updateEditButtonStateIfNeeded() {
        buttonEditModeState = editMode
    }

    private func updateEditButton() {
        if let editButton {
            navigationItem.setRightBarButtonItems([editButton] + customItems, animated: true)
        } else {
            navigationItem.setRightBarButtonItems(customItems, animated: true)
        }
    }
}
