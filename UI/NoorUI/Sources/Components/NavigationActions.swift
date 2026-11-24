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

    /// Done keeps its place when the bar runs out of room, like in iPhone Duo's vertical bar, so finishing
    /// an edit never hides in an overflow menu.
    public static func done(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        let button = button(systemItem: .done, tintColor: nil, action: action)
        if #available(iOS 27.0, *) {
            button.visibilityPriority = .high
        }
        return button
    }

    public static func close(action: @escaping @MainActor @Sendable () -> Void) -> UIBarButtonItem {
        button(systemItem: .close, tintColor: .label, action: action)
    }

    public static func add(
        accessibilityLabel: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(image: NoorSystemImage.plus.uiImage, title: accessibilityLabel, tintColor: nil, action: action)
    }

    /// The destructive Delete All shown while editing a list. Its action gets the button, so a confirmation
    /// can anchor its popover to it.
    public static func deleteAll(action: @escaping @MainActor (UIBarButtonItem) -> Void) -> UIBarButtonItem {
        let button = UIBarButtonItem()
        button.primaryAction = UIAction(title: l("bookmarks.delete-all")) { [weak button] _ in
            guard let button else {
                return
            }
            action(button)
        }
        button.tintColor = .systemRed
        return button
    }

    /// Pass `glassSymbolScale` for symbols that are both wide and tall, such as `books.vertical`:
    /// Liquid Glass draws each bar button inside a 44pt circle, which they crowd at the default scale.
    public static func secondary(
        image: NoorSystemImage,
        accessibilityLabel: String,
        glassSymbolScale: UIImage.SymbolScale? = nil,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(
            image: symbol(image, glassSymbolScale: glassSymbolScale),
            title: accessibilityLabel,
            tintColor: .label,
            action: action
        )
    }

    /// A secondary action with an image that isn't an SF Symbol, like the reading bookmark's ribbon.
    public static func secondary(
        customImage: UIImage?,
        accessibilityLabel: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(image: customImage, title: accessibilityLabel, tintColor: .label, action: action)
    }

    /// Shares a whole list. It inherits the window tint, as it always has.
    public static func share(
        accessibilityLabel: String,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        button(image: NoorSystemImage.share.uiImage, title: accessibilityLabel, tintColor: nil, action: action)
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
            NoorSystemImage.more.uiImage
        } else {
            NoorSystemImage.moreCircle.uiImage
        }
    }

    // MARK: Private

    private static func symbol(_ systemImage: NoorSystemImage, glassSymbolScale: UIImage.SymbolScale?) -> UIImage? {
        let image = systemImage.uiImage
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
        title: String? = nil,
        tintColor: UIColor?,
        action: @escaping @MainActor @Sendable () -> Void
    ) -> UIBarButtonItem {
        let button = if let title {
            TitledBarButtonItem(image: image, title: title, action: action)
        } else {
            UIBarButtonItem(
                image: image,
                primaryAction: UIAction { _ in action() }
            )
        }
        if let tintColor {
            button.tintColor = tintColor
        }
        return button
    }
}

/// An icon-only bar item that names itself for VoiceOver and for the menu that collects bar items when the bar
/// runs out of room, like iPhone Duo's vertical bar, which otherwise lists the icon without a title.
/// The bar itself still shows only the icon.
final class TitledBarButtonItem: UIBarButtonItem {
    // MARK: Lifecycle

    init(image: UIImage?, title: String, action: @escaping @MainActor @Sendable () -> Void) {
        menuAction = action
        super.init()
        primaryAction = UIAction { _ in action() }
        self.image = image
        accessibilityLabel = title
        updateMenuRepresentation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    // UIKit doesn't carry the item's state to its menu representation, so the menu entry follows it here,
    // like Next and Previous turning off at the last and first verses.
    override var isEnabled: Bool {
        didSet { updateMenuRepresentation() }
    }

    override var image: UIImage? {
        didSet { updateMenuRepresentation() }
    }

    /// The menu entry's title, like a bookmark button's Add or Remove.
    override var accessibilityLabel: String? {
        didSet { updateMenuRepresentation() }
    }

    // MARK: Private

    private let menuAction: @MainActor @Sendable () -> Void

    private func updateMenuRepresentation() {
        guard #available(iOS 16.0, *) else {
            return
        }
        let action = menuAction
        menuRepresentation = UIAction(
            title: accessibilityLabel ?? "",
            image: image,
            attributes: isEnabled ? [] : .disabled
        ) { _ in action() }
    }
}

@MainActor
public final class NavigationEditModeController {
    /// `listItems` show only alongside the Edit button, while there is a list to edit.
    public init(
        navigationItem: UINavigationItem,
        reload: AnyPublisher<Void, Never>,
        editMode: Binding<EditMode?>,
        listItems: [UIBarButtonItem] = [],
        customItems: [UIBarButtonItem] = []
    ) {
        controller = EditController(
            navigationItem: navigationItem,
            reload: reload,
            editMode: editMode,
            listItems: listItems,
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
                NoorSystemImage.cancel.image
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
            if #available(iOS 26, *) {
                // Liquid Glass draws the primary action as tinted glass, like Done.
                Button(action: action) {
                    image.image
                }
                .buttonStyle(.glassProminent)
                .accessibilityLabel(accessibilityLabel)
            } else {
                Button(action: action) {
                    image.image
                }
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel(accessibilityLabel)
            }
        }
    }

    private let image: NoorSystemImage
    private let accessibilityLabel: String
    private let action: @MainActor @Sendable () -> Void
}
