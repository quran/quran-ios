import UIKit
import XCTest
@testable import AppStructureFeature

@MainActor
final class AppViewControllerTests: XCTestCase {
    func test_synchronizeTabBarContainerVisibilityHidesContainerWithTabBar() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Tab bar scroll-edge effects require iOS 26.")
        }
        let sut = UITabBarController()
        sut.loadViewIfNeeded()
        let containerView = try XCTUnwrap(sut.tabBar.superview?.superview)
        sut.tabBar.isHidden = true

        sut.synchronizeTabBarContainerVisibility()

        XCTAssertTrue(containerView.isHidden)
    }

    func test_synchronizeTabBarContainerVisibilityShowsContainerWithTabBar() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("Tab bar scroll-edge effects require iOS 26.")
        }
        let sut = UITabBarController()
        sut.loadViewIfNeeded()
        let containerView = try XCTUnwrap(sut.tabBar.superview?.superview)
        containerView.isHidden = true

        sut.synchronizeTabBarContainerVisibility()

        XCTAssertFalse(containerView.isHidden)
    }
}
