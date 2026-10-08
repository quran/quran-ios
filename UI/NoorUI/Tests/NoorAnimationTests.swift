import UIKit
import XCTest
@testable import NoorUI

@MainActor
final class NoorAnimationTests: XCTestCase {
    // MARK: Internal

    func test_animate_runsChangesWithCoreAnimation() {
        let (window, view) = makeVisibleView()

        NoorAnimation.animate {
            view.alpha = 0
        }

        // A SwiftUI animation adds no Core Animation animation. UIKit advances it on its in-process
        // animation thread, which can lay out SwiftUI hosting views off the main thread.
        let animation = view.layer.animation(forKey: "opacity")
        XCTAssertNotNil(animation)
        XCTAssertEqual(animation?.duration, 0.3)
        window.isHidden = true
    }

    func test_animate_callsCompletion() {
        let (window, view) = makeVisibleView()
        let completed = expectation(description: "Animation completed")

        NoorAnimation.animate {
            view.alpha = 0
        } completion: {
            completed.fulfill()
        }

        wait(for: [completed], timeout: 2)
        window.isHidden = true
    }

    // MARK: Private

    private func makeVisibleView() -> (UIWindow, UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(view)
        window.makeKeyAndVisible()
        return (window, view)
    }
}
