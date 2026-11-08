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
        XCTAssertEqual(navigationItem.rightBarButtonItems?.dropFirst(), [share, search])

        state.editMode = nil
        reload.send()
        await drainMainQueue()
        XCTAssertEqual(navigationItem.rightBarButtonItems, [search])
        withExtendedLifetime(controller) {}
    }

    // MARK: Private

    private final class EditModeState {
        var editMode: EditMode?
    }

    /// Runs the controller's reload, which it receives on the next main-queue turn.
    private func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { continuation.resume() }
        }
    }
}
