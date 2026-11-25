import Localization
import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NavigationActionsTests: XCTestCase {
    func test_editButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.edit { },
            systemItem: .edit,
            tintColor: .label
        )
    }

    func test_doneButton_usesSystemPresentation() {
        // Inherits the window tint, which follows the app icon accent.
        assertSystemPresentation(
            NavigationBarButton.done { },
            systemItem: .done,
            tintColor: nil
        )
    }

    func test_closeButton_usesSystemPresentation() {
        assertSystemPresentation(
            NavigationBarButton.close { },
            systemItem: .close,
            tintColor: .label
        )
    }

    func test_doneButton_keepsItsPlaceWhenTheBarRunsOutOfRoom() throws {
        guard #available(iOS 27.0, *) else {
            throw XCTSkip("Bar item visibility priority needs iOS 27.")
        }

        XCTAssertEqual(NavigationBarButton.done { }.visibilityPriority, .high)
        XCTAssertEqual(NavigationBarButton.edit { }.visibilityPriority, .standard)
    }

    func test_addButton_inheritsWindowTint() {
        let button = NavigationBarButton.add(accessibilityLabel: "Add Collection") { }

        XCTAssertNil(button.tintColor)
        XCTAssertNotNil(button.primaryAction)
    }

    func test_addButton_isTitledInMenusButShowsOnlyItsIcon() {
        let button = NavigationBarButton.add(accessibilityLabel: "Add Collection") { }

        assertMenuTitle(button, "Add Collection")
    }

    func test_deleteAllButton_isRedAndTitled() {
        let button = NavigationBarButton.deleteAll { _ in }

        XCTAssertEqual(button.title, l("bookmarks.delete-all"))
        XCTAssertEqual(button.tintColor, .systemRed)
        XCTAssertNotNil(button.primaryAction)
    }

    func test_overflowButton_dropsTheCircleOnLiquidGlass() {
        let expectedSymbol = if #available(iOS 26, *) {
            "ellipsis"
        } else {
            "ellipsis.circle"
        }

        XCTAssertEqual(NavigationBarButton.overflow { }.image, UIImage(systemName: expectedSymbol))
        XCTAssertEqual(NavigationBarButton.overflow(menu: UIMenu(children: [])).image, UIImage(systemName: expectedSymbol))
    }

    func test_secondaryButton_appliesGlassSymbolScaleOnLiquidGlass() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)))

        let button = NavigationBarButton.secondary(
            image: .mushafs,
            accessibilityLabel: "Books",
            glassSymbolScale: .medium
        ) { }

        let mediumSymbol = UIImage(systemName: "books.vertical")?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(scale: .medium))
        XCTAssertEqual(button.image, mediumSymbol)
        XCTAssertNotEqual(button.image, UIImage(systemName: "books.vertical"))
        XCTAssertEqual(button.tintColor, .label)
    }

    func test_secondaryButton_keepsTheDefaultScaleWithoutGlassSymbolScale() {
        let button = NavigationBarButton.secondary(image: .mushafs, accessibilityLabel: "Books") { }

        XCTAssertEqual(button.image, UIImage(systemName: "books.vertical"))
    }

    func test_secondaryButton_usesAccessibilityLabel() {
        let button = NavigationBarButton.secondary(image: .mushafs, accessibilityLabel: "Books") { }

        XCTAssertEqual(button.accessibilityLabel, "Books")
    }

    func test_secondaryButton_isTitledInMenusButShowsOnlyItsIcon() {
        let button = NavigationBarButton.secondary(image: .mushafs, accessibilityLabel: "Books") { }

        assertMenuTitle(button, "Books")
    }

    func test_shareButton_inheritsWindowTintAndIsTitledInMenus() {
        let button = NavigationBarButton.share(accessibilityLabel: "Share...") { }

        XCTAssertNil(button.tintColor)
        XCTAssertEqual(button.image, NoorSystemImage.share.uiImage)
        assertMenuTitle(button, "Share...")
    }

    func test_menuEntry_runsTheItemsAction() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Bar item menu representations need iOS 16.")
        }
        let taps = TapCounter()
        let button = NavigationBarButton.share(accessibilityLabel: "Share...") { taps.count += 1 }

        let action = try XCTUnwrap(button.menuRepresentation as? UIAction)
        action.performWithSender(nil, target: nil)

        XCTAssertEqual(taps.count, 1)
    }

    func test_menuEntry_followsTheItemsEnabledState() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Bar item menu representations need iOS 16.")
        }
        let button = NavigationBarButton.secondary(image: .nextVerse, accessibilityLabel: "Next") { }

        button.isEnabled = false
        let disabled = try XCTUnwrap(button.menuRepresentation as? UIAction)
        XCTAssertTrue(disabled.attributes.contains(.disabled))

        button.isEnabled = true
        let enabled = try XCTUnwrap(button.menuRepresentation as? UIAction)
        XCTAssertFalse(enabled.attributes.contains(.disabled))
        XCTAssertEqual(enabled.title, "Next")
    }

    func test_menuEntry_followsTheItemsImage() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Bar item menu representations need iOS 16.")
        }
        let button = NavigationBarButton.secondary(image: .nextVerse, accessibilityLabel: "Next") { }

        button.image = NoorSystemImage.previousVerse.uiImage

        let action = try XCTUnwrap(button.menuRepresentation as? UIAction)
        XCTAssertEqual(action.image, NoorSystemImage.previousVerse.uiImage)
    }

    func test_menuEntry_followsTheItemsAccessibilityLabel() throws {
        guard #available(iOS 16.0, *) else {
            throw XCTSkip("Bar item menu representations need iOS 16.")
        }
        let button = NavigationBarButton.secondary(image: .bookmarkOutline, accessibilityLabel: "Bookmark page") { }

        button.accessibilityLabel = "Remove page bookmark"

        let action = try XCTUnwrap(button.menuRepresentation as? UIAction)
        XCTAssertEqual(action.title, "Remove page bookmark")
    }

    @MainActor
    private final class TapCounter {
        var count = 0
    }

    /// The overflow menu that collects bar items, like iPhone Duo's vertical bar, lists the title,
    /// while the bar shows only the icon.
    private func assertMenuTitle(
        _ button: UIBarButtonItem,
        _ title: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if #available(iOS 16.0, *) {
            let menuAction = button.menuRepresentation as? UIAction
            XCTAssertEqual(menuAction?.title, title, file: file, line: line)
            XCTAssertEqual(menuAction?.image, button.image, file: file, line: line)
        }
        XCTAssertEqual(button.accessibilityLabel, title, file: file, line: line)
        XCTAssertNil(button.title, file: file, line: line)
        XCTAssertNotNil(button.image, file: file, line: line)
    }

    private func assertSystemPresentation(
        _ button: UIBarButtonItem,
        systemItem: UIBarButtonItem.SystemItem,
        tintColor: UIColor?,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expected = UIBarButtonItem(barButtonSystemItem: systemItem, target: nil, action: nil)

        XCTAssertEqual(button.title, expected.title, file: file, line: line)
        XCTAssertEqual(button.tintColor, tintColor, file: file, line: line)
        XCTAssertNotNil(button.primaryAction, file: file, line: line)
    }
}
