//
//  NavigationActions.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import Combine
import Localization
import SwiftUI
import UIKit
import UIx

@MainActor
public enum NavigationBarButton {
    public static func edit(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .edit, tintColor: nil, action: action)
    }

    public static func done(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .done, tintColor: .appIdentity, action: action)
    }

    public static func close(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .close, tintColor: nil, action: action)
    }

    public static func add(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemName: "plus", tintColor: .appIdentity, action: action)
    }

    public static func secondary(
        systemName: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(systemName: systemName, tintColor: .label, action: action)
    }

    public static func overflow(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        secondary(systemName: "ellipsis.circle", action: action)
    }

    public static func overflow(menu: UIMenu) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            menu: menu
        )
        button.tintColor = .label
        return button
    }

    private static func button(
        systemItem: UIBarButtonItem.SystemItem,
        tintColor: UIColor?,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            systemItem: systemItem,
            primaryAction: UIAction { _ in action() }
        )
        if let tintColor {
            button.tintColor = tintColor
        }
        return button
    }

    private static func button(
        systemName: String,
        tintColor: UIColor,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: systemName),
            primaryAction: UIAction { _ in action() }
        )
        button.tintColor = tintColor
        return button
    }
}

@MainActor
public final class NavigationEditModeController {
    public init(
        navigationItem: UINavigationItem,
        reload: AnyPublisher<Void, Never>,
        editMode: Binding<EditMode?>,
        customItems: [UIBarButtonItem] = []
    ) {
        controller = EditController(
            navigationItem: navigationItem,
            reload: reload,
            editMode: editMode,
            customItems: customItems,
            buttonProvider: { editMode, action in
                if editMode.isEditing {
                    NavigationBarButton.done(action: action)
                } else {
                    NavigationBarButton.edit(action: action)
                }
            }
        )
    }

    private let controller: EditController
}

public struct EditModeButton: View {
    public init(editMode: Binding<EditMode>) {
        _editMode = editMode
    }

    public var body: some View {
        EditButton()
            .environment(\.editMode, $editMode)
            .foregroundStyle(editMode.isEditing ? Color.appIdentity : Color.label)
    }

    @Binding private var editMode: EditMode
}

public struct DoneToolbarItem: ToolbarContent {
    public init(action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(l("button.done"), action: action)
                .foregroundStyle(Color.appIdentity)
        }
    }

    private let action: @MainActor @Sendable () -> Void
}

public struct CloseToolbarItem: ToolbarContent {
    public init(action: @escaping @MainActor @Sendable () -> Void) {
        self.action = action
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(action: action) {
                Image(systemName: "xmark")
            }
            .foregroundStyle(Color.label)
            .accessibilityLabel(l("button.close"))
        }
    }

    private let action: @MainActor @Sendable () -> Void
}
