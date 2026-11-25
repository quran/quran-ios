import Combine
import SwiftUI
import UIKit
import XCTest
@testable import UIx

@MainActor
final class EditControllerTests: XCTestCase {
    func test_listItems_showOnlyAlongsideTheEditButton() async {
        let navigationItem = UINavigationItem()
        let reload = PassthroughSubject<Void, Never>()
        let state = EditModeState()
        let share = UIBarButtonItem(systemItem: .action)
        let search = UIBarButtonItem(systemItem: .search)
        let controller = EditController(
            navigationItem: navigationItem,
            reload: reload.eraseToAnyPublisher(),
            editMode: Binding(get: { state.editMode }, set: { state.editMode = $0 }),
            listItems: [share],
            customItems: [search]
        )
        XCTAssertEqual(navigationItem.rightBarButtonItems, [search])

        state.editMode = .inactive
        reload.send()
        await drainMainQueue()
        let items = navigationItem.rightBarButtonItems ?? []
        XCTAssertEqual(items.count, 3, "Edit, then the list and custom items")
        XCTAssertEqual(items.dropFirst(), [share, search])

        state.editMode = nil
        reload.send()
        await drainMainQueue()
        XCTAssertEqual(navigationItem.rightBarButtonItems, [search])
        withExtendedLifetime(controller) {}
    }

    func test_editing_letsTheVerticalBarCompressTheTabBarFirst() async throws {
        guard #available(iOS 27.1, *) else {
            throw XCTSkip("The vertical bar compression behavior needs iOS 27.1.")
        }
        let navigationItem = RetainingNavigationItem()
        let reload = PassthroughSubject<Void, Never>()
        let state = EditModeState()
        state.editMode = .inactive
        let controller = EditController(
            navigationItem: navigationItem,
            reload: reload.eraseToAnyPublisher(),
            editMode: Binding(get: { state.editMode }, set: { state.editMode = $0 })
        )
        XCTAssertEqual(navigationItem.verticalBarCompressionBehavior, .automatic)

        state.editMode = .active
        reload.send()
        await drainMainQueue()
        XCTAssertEqual(navigationItem.verticalBarCompressionBehavior, .prefersBarItems)

        state.editMode = .inactive
        reload.send()
        await drainMainQueue()
        XCTAssertEqual(navigationItem.verticalBarCompressionBehavior, .automatic)

        state.editMode = .active
        reload.send()
        await drainMainQueue()
        state.editMode = nil
        reload.send()
        await drainMainQueue()
        XCTAssertEqual(navigationItem.verticalBarCompressionBehavior, .automatic)
        withExtendedLifetime(controller) {}
    }

    // MARK: Private

    private final class EditModeState {
        var editMode: EditMode?
    }

    /// UIKit keeps this value only on devices with a vertical bar, so the test item keeps it itself.
    private final class RetainingNavigationItem: UINavigationItem {
        @available(iOS 27.1, *)
        override var verticalBarCompressionBehavior: UIVerticalBarCompressionBehavior {
            get { UIVerticalBarCompressionBehavior(rawValue: verticalBarCompressionBehaviorRawValue) ?? .automatic }
            set { verticalBarCompressionBehaviorRawValue = newValue.rawValue }
        }

        private var verticalBarCompressionBehaviorRawValue = 0
    }

    /// Runs the controller's reload, which it receives on the next main-queue turn.
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
