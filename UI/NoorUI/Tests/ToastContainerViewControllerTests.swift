import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class ToastContainerViewControllerTests: XCTestCase {
    func testAppRootSetsTheStatusBarAndHomeIndicator() {
        let root = UIViewController()

        XCTAssertIdentical(appScreen(root: root), root)
    }

    func testFullScreenPresentedScreenTakesThemOver() {
        let fullScreen = UIViewController()
        fullScreen.modalPresentationStyle = .fullScreen

        XCTAssertIdentical(appScreen(root: UIViewController(), presenting: fullScreen), fullScreen)
    }

    func testSheetLeavesThemToTheScreenUnderIt() {
        let root = UIViewController()

        XCTAssertIdentical(appScreen(root: root, presenting: UIViewController()), root)
    }

    func testSheetThatCapturesTheStatusBarTakesThemOver() {
        let sheet = UIViewController()
        sheet.modalPresentationCapturesStatusBarAppearance = true

        XCTAssertIdentical(appScreen(root: UIViewController(), presenting: sheet), sheet)
    }

    // MARK: Private

    /// Shows `root` in a window, presents `screen` over it, and reads the screen the toast defers to.
    private func appScreen(root: UIViewController, presenting screen: UIViewController? = nil) -> UIViewController? {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        window.rootViewController = root
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        if let screen {
            root.present(screen, animated: false)
            XCTAssertIdentical(root.presentedViewController, screen)
        }
        return ToastContainerViewController.appScreen(in: [window])
    }
}
