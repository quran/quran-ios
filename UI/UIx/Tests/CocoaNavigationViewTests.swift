import SwiftUI
import XCTest
@testable import UIx

@MainActor
final class CocoaNavigationViewTests: XCTestCase {
    func testNavigatorDoesNotRetainNavigationController() {
        var navigationController: UINavigationController? = UINavigationController()
        weak let weakNavigationController = navigationController
        let navigator = Navigator(navigationController: navigationController!)

        navigationController = nil

        XCTAssertNil(weakNavigationController)
        XCTAssertNil(navigator.navigationController)
    }

    func testRootHostingControllerUsesConcreteViewType() {
        let navigationController = UINavigationController()
        let rootController = makeNavigationRootController(
            root: Text("Root"),
            navigator: Navigator(navigationController: navigationController),
            configuration: nil
        )

        XCTAssertFalse(String(reflecting: type(of: rootController)).contains("AnyView"))
    }
}
