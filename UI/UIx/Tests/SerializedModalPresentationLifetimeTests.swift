import XCTest
@testable import UIx

@MainActor
final class SerializedModalPresentationLifetimeTests: XCTestCase {
    func testPresenterReferenceDoesNotRetainViewController() {
        let reference = WeakViewControllerReference()
        weak var weakViewController: UIViewController?

        autoreleasepool {
            let viewController = UIViewController()
            weakViewController = viewController
            reference.set(viewController)
            XCTAssertTrue(reference.value === viewController)
            XCTAssertEqual(reference.resolutionRevision, 1)

            reference.clear()
            reference.set(viewController)
            XCTAssertEqual(reference.resolutionRevision, 2)
        }

        XCTAssertNil(weakViewController)
        XCTAssertNil(reference.value)
    }
}
