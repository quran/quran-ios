import SwiftUI
import XCTest
@testable import NoorUI

@MainActor
final class QuranScrollingViewModifierTests: XCTestCase {
    // MARK: Internal

    override func setUp() {
        super.setUp()
        // The package test runner has no window scene to drive scroll animations.
        animationsWereEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
    }

    override func tearDown() {
        UIView.setAnimationsEnabled(animationsWereEnabled)
        super.tearDown()
    }

    func test_scrollsToTargetThatArrivesWithItsItemsInOneUpdate() throws {
        let model = ScrollingListModel()
        let window = makeWindow(model: model)
        defer { window.isHidden = true }

        // A translation page loads its rows and its deep-link target together.
        model.content = ScrollingListContent(items: Array(0 ..< 200), target: 150)

        let scrollView = try XCTUnwrap(waitForScrollView(in: window))
        XCTAssertTrue(
            waitUntil(window: window) { scrollView.contentOffset.y > scrollView.bounds.height },
            "The list should scroll to the target row; offset: \(scrollView.contentOffset.y)"
        )
    }

    func test_scrollsToTargetOnceItsItemsArriveInALaterUpdate() throws {
        let model = ScrollingListModel()
        let window = makeWindow(model: model)
        defer { window.isHidden = true }
        model.content.target = 150
        let scrollView = try XCTUnwrap(waitForScrollView(in: window))
        spinRunLoop(window: window)
        XCTAssertLessThanOrEqual(scrollView.contentOffset.y, 0, "An unresolved target must not scroll")

        model.content.items = Array(0 ..< 200)

        XCTAssertTrue(
            waitUntil(window: window) { scrollView.contentOffset.y > scrollView.bounds.height },
            "The list should scroll to the target row; offset: \(scrollView.contentOffset.y)"
        )
    }

    func test_doesNotScrollToTargetMissingFromItems() throws {
        let model = ScrollingListModel()
        let window = makeWindow(model: model)
        defer { window.isHidden = true }

        model.content = ScrollingListContent(items: Array(0 ..< 200), target: 500)

        let scrollView = try XCTUnwrap(waitForScrollView(in: window))
        XCTAssertTrue(waitUntil(window: window) { scrollView.contentSize.height > scrollView.bounds.height })
        spinRunLoop(window: window)
        XCTAssertLessThanOrEqual(scrollView.contentOffset.y, 0, "A target missing from the items must not scroll")
    }

    // MARK: Private

    private var animationsWereEnabled = true

    private func makeWindow(model: ScrollingListModel) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = UIHostingController(rootView: ScrollingListView(model: model))
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        return window
    }

    private func waitForScrollView(in window: UIWindow) -> UIScrollView? {
        var scrollView: UIScrollView?
        _ = waitUntil(window: window) {
            scrollView = window.firstDescendant(ofType: UIScrollView.self)
            return scrollView != nil
        }
        return scrollView
    }

    /// Gives pending view updates and deferred scrolls a chance to run.
    private func spinRunLoop(window: UIWindow) {
        _ = waitUntil(window: window, timeout: 0.2) { false }
    }

    private func waitUntil(window: UIWindow, timeout: TimeInterval = 2, _ condition: () -> Bool) -> Bool {
        let deadline = Date(timeIntervalSinceNow: timeout)
        while true {
            window.layoutIfNeeded()
            if condition() {
                return true
            }
            guard Date() < deadline else { return false }
            RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.01))
        }
    }
}

private struct ScrollingListContent {
    var items: [Int] = []
    var target: Int?
}

private final class ScrollingListModel: ObservableObject {
    @Published var content = ScrollingListContent()
}

private struct ScrollingListView: View {
    @ObservedObject var model: ScrollingListModel

    var body: some View {
        ScrollingListBody(items: model.content.items, target: model.content.target)
    }
}

/// Mirrors the translation list: the transform validates the target against the rendered rows.
private struct ScrollingListBody: View {
    let items: [Int]
    let target: Int?

    var body: some View {
        List {
            ForEach(items, id: \.self) { item in
                Text(verbatim: "Row \(item)")
            }
        }
        .listStyle(.plain)
        .quranScrolling(scrollToValue: target, onReaderScroll: {}) { target in
            items.contains(target) ? target : nil
        }
    }
}

extension UIView {
    fileprivate func firstDescendant<T: UIView>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T ?? subview.firstDescendant(ofType: type) {
                return match
            }
        }
        return nil
    }
}
