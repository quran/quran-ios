//
//  NavigationActions.swift
//
//
//  Created by Mohamed Afifi on 2026-07-26.
//

import Localization
import SwiftUI
import UIKit

@MainActor
public enum NavigationBarButton {
    public static func edit(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .edit, action: action)
    }

    public static func done(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .done, action: action)
    }

    public static func close(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .close, action: action)
    }

    private static func button(
        systemItem: UIBarButtonItem.SystemItem,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            systemItem: systemItem,
            primaryAction: UIAction { _ in action() }
        )
        button.tintColor = .appIdentity
        return button
    }
}

public struct EditModeButton: View {
    public init(editMode: Binding<EditMode>) {
        _editMode = editMode
    }

    public var body: some View {
        EditButton()
            .environment(\.editMode, $editMode)
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
        }
    }

    private let action: @MainActor @Sendable () -> Void
}

public struct CloseToolbarItem: ToolbarContent {
    @Environment(\.dismiss) private var dismiss

    public init() { }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(l("button.close")) {
                dismiss()
            }
        }
    }
}
