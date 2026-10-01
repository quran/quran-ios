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

/// Done and Add inherit the window tint, so they follow the app icon accent live.
/// Edit, Close, overflow, and secondary actions stay neutral.
@MainActor
public enum NavigationBarButton {
    public static func edit(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .edit, tintColor: .label, action: action)
    }

    public static func done(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .done, tintColor: nil, action: action)
    }

    public static func close(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .close, tintColor: .label, action: action)
    }

    public static func add(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(image: UIImage(systemName: "plus"), tintColor: nil, action: action)
    }

    /// Pass `glassSymbolScale` for symbols that are both wide and tall, such as `books.vertical`:
    /// Liquid Glass draws each bar button inside a 44pt circle, which they crowd at the default scale.
    public static func secondary(
        systemName: String,
        glassSymbolScale: UIImage.SymbolScale? = nil,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(image: symbol(systemName, glassSymbolScale: glassSymbolScale), tintColor: .label, action: action)
    }

    public static func overflow(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(image: overflowImage, tintColor: .label, action: action)
    }

    public static func overflow(menu: UIMenu) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: overflowImage,
            menu: menu
        )
        button.tintColor = .label
        return button
    }

    /// Liquid Glass already wraps each bar button in a circle, so a circled ellipsis would draw two.
    public static var overflowImage: UIImage? {
        if #available(iOS 26, *) {
            UIImage(systemName: "ellipsis")
        } else {
            UIImage(systemName: "ellipsis.circle")
        }
    }

    // MARK: Private

    private static func symbol(_ systemName: String, glassSymbolScale: UIImage.SymbolScale?) -> UIImage? {
        let image = UIImage(systemName: systemName)
        guard #available(iOS 26, *), let glassSymbolScale else {
            return image
        }
        return image?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: glassSymbolScale))
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
        image: UIImage?,
        tintColor: UIColor?,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: image,
            primaryAction: UIAction { _ in action() }
        )
        if let tintColor {
            button.tintColor = tintColor
        }
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
            .foregroundStyle(editMode.isEditing ? Color.accentColor : Color.label)
    }

    @Binding private var editMode: EditMode
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

/// The screen's primary action, such as Play. Like Done, it inherits the window tint,
/// so it follows the app icon accent live.
public struct PrimaryActionToolbarItem: ToolbarContent {
    public init(
        image: NoorSystemImage,
        accessibilityLabel: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) {
        self.image = image
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            PrimaryActionButton(image: image, action: action)
                .accessibilityLabel(accessibilityLabel)
        }
    }

    private let image: NoorSystemImage
    private let accessibilityLabel: String
    private let action: @MainActor @Sendable () -> Void
}

private struct PrimaryActionButton: View {
    let image: NoorSystemImage
    let action: @MainActor @Sendable () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            // Liquid Glass draws the primary action as tinted glass, like Done.
            Button(action: action) {
                image.image
            }
            .buttonStyle(.glassProminent)
        } else {
            Button(action: action) {
                image.image
            }
            .foregroundStyle(Color.accentColor)
        }
    }
}
