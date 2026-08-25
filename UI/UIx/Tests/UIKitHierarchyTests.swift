import UIKit
import XCTest
@testable import UIx

@MainActor
final class UIKitHierarchyTests: XCTestCase {
    func test_nearestViewControllerWalksUpResponderChain() {
        let viewController = UIViewController()
        let containerView = UIView()
        let nestedView = UIView()
        viewController.view.addSubview(containerView)
        containerView.addSubview(nestedView)

        XCTAssertIdentical(nestedView.nearestViewController, viewController)
    }

    func test_findViewControllerSearchesContainedViewControllers() {
        let rootViewController = UIViewController()
        let containerViewController = UIViewController()
        let pageViewController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal
        )
        rootViewController.addChild(containerViewController)
        containerViewController.addChild(pageViewController)

        XCTAssertIdentical(
            rootViewController.findViewController(ofType: UIPageViewController.self),
            pageViewController
        )
    }

    func test_mostVisibleSubviewReturnsSubviewWithLargestVisibleArea() {
        let rootView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let mostlyOffscreenScrollView = UIScrollView(frame: CGRect(x: -90, y: 0, width: 100, height: 100))
        let visibleScrollView = UIScrollView(frame: CGRect(x: 10, y: 0, width: 80, height: 100))
        rootView.addSubview(mostlyOffscreenScrollView)
        rootView.addSubview(visibleScrollView)

        XCTAssertIdentical(
            rootView.mostVisibleSubview(ofType: UIScrollView.self),
            visibleScrollView
        )
    }

    func test_mostVisibleViewControllerReturnsControllerWithLargestVisibleArea() {
        let mostlyOffscreenViewController = UIViewController()
        let visibleViewController = UIViewController()
        let pageViewController = TestPageViewController(
            viewControllers: [mostlyOffscreenViewController, visibleViewController]
        )
        pageViewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        pageViewController.view.addSubview(mostlyOffscreenViewController.view)
        pageViewController.view.addSubview(visibleViewController.view)
        mostlyOffscreenViewController.view.frame = CGRect(x: -90, y: 0, width: 100, height: 100)
        visibleViewController.view.frame = CGRect(x: 10, y: 0, width: 80, height: 100)

        XCTAssertIdentical(pageViewController.mostVisibleViewController, visibleViewController)
    }

    func test_mostVisibleViewControllerIgnoresHiddenController() {
        let hiddenViewController = UIViewController()
        let visibleViewController = UIViewController()
        let pageViewController = TestPageViewController(
            viewControllers: [hiddenViewController, visibleViewController]
        )
        pageViewController.view.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        pageViewController.view.addSubview(hiddenViewController.view)
        pageViewController.view.addSubview(visibleViewController.view)
        hiddenViewController.view.frame = pageViewController.view.bounds
        hiddenViewController.view.isHidden = true
        visibleViewController.view.frame = CGRect(x: 0, y: 0, width: 50, height: 100)

        XCTAssertIdentical(pageViewController.mostVisibleViewController, visibleViewController)
    }
}

private final class TestPageViewController: UIPageViewController {
    init(viewControllers: [UIViewController]) {
        testViewControllers = viewControllers
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var viewControllers: [UIViewController]? {
        testViewControllers
    }

    private let testViewControllers: [UIViewController]
}
