import SwiftUI
import UIKit
import UIKit.UIGestureRecognizerSubclass
import XCTest
@testable import UIx

@MainActor
final class ScrollDragObserverTests: XCTestCase {
    func test_observesScrollViewInsteadOfEnclosingPagerScrollView() throws {
        var drags = 0
        let host = host(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan { drags += 1 }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let scrollView = try XCTUnwrap(host.content.findSubview(ofType: UIScrollView.self))
        XCTAssertIdentical(observer.scrollView, scrollView)
        XCTAssertNotIdentical(observer.scrollView, host.pager)

        // XCTest can't drive a real pan; deliver the observed gesture's `.began` directly.
        observer.panGestureChanged(PanGesture(state: .began))
        XCTAssertEqual(drags, 1)
    }

    func test_dragOnContentThatFitsDoesNotRunAction() throws {
        var drags = 0
        let host = host(
            ScrollView {
                Color.clear.frame(height: 100)
            }
            .onScrollDragBegan { drags += 1 }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertNotNil(observer.scrollView)
        observer.panGestureChanged(PanGesture(state: .began))

        XCTAssertEqual(drags, 0)
    }

    func test_contentWithoutScrollViewDoesNotObserveEnclosingPager() throws {
        let host = host(
            Color.clear
                .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertNil(observer.scrollView)
    }

    func test_stopsObservingWhenLeavingTheWindow() throws {
        let host = host(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }
        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertNotNil(observer.scrollView)

        host.content.removeFromSuperview()

        XCTAssertNil(observer.scrollView)
    }

    func test_observesListInsteadOfScrollViewsInItsRows() throws {
        var drags = 0
        let host = host(
            List {
                ForEach(0 ..< 50, id: \.self) { row in
                    RowTextView(text: "Row \(row)")
                }
            }
            .onScrollDragBegan { drags += 1 }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let list = try XCTUnwrap(host.content.findSubview(ofType: UIScrollView.self))
        XCTAssertFalse(list is UITextView)
        XCTAssertIdentical(observer.scrollView, list)
        XCTAssertNotIdentical(observer.scrollView, host.pager)

        observer.panGestureChanged(PanGesture(state: .began))
        XCTAssertEqual(drags, 1)
    }

    func test_programmaticScrollingAndOngoingDragsDoNotRunAction() throws {
        var drags = 0
        let host = host(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan { drags += 1 }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let scrollView = try XCTUnwrap(host.content.findSubview(ofType: UIScrollView.self))
        scrollView.setContentOffset(CGPoint(x: 0, y: 500), animated: false)
        drainMainQueue()
        observer.panGestureChanged(PanGesture(state: .changed))
        observer.panGestureChanged(PanGesture(state: .ended))

        XCTAssertEqual(drags, 0)
    }

    // MARK: Private

    private final class PanGesture: UIPanGestureRecognizer {
        init(state: UIGestureRecognizer.State) {
            fixedState = state
            super.init(target: nil, action: nil)
        }

        override var state: UIGestureRecognizer.State {
            get { fixedState }
            // Keep the state the test asked for, even when UIKit resets it.
            set {}
        }

        private let fixedState: UIGestureRecognizer.State
    }

    private struct RowTextView: UIViewRepresentable {
        let text: String

        func makeUIView(context: Context) -> UITextView {
            let view = UITextView()
            view.isScrollEnabled = false
            return view
        }

        func updateUIView(_ view: UITextView, context: Context) {
            view.text = text
        }
    }

    /// Hosts `view` in a page inside a horizontal pager scroll view, like the Quran pages.
    private func host(_ view: some View) -> (window: UIWindow, pager: UIScrollView, content: UIView) {
        let frame = CGRect(x: 0, y: 0, width: 400, height: 600)
        let root = UIViewController()
        let pager = UIScrollView(frame: frame)
        pager.contentSize = CGSize(width: frame.width * 3, height: frame.height)
        root.view.addSubview(pager)

        let page = UIHostingController(rootView: view)
        root.addChild(page)
        page.view.frame = frame.offsetBy(dx: frame.width, dy: 0)
        pager.addSubview(page.view)
        page.didMove(toParent: root)
        pager.contentOffset = CGPoint(x: frame.width, y: 0)

        let window = UIWindow(frame: frame)
        window.rootViewController = root
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        page.view.layoutIfNeeded()
        drainMainQueue()
        return (window, pager, page.view)
    }

    private func drainMainQueue() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
    }
}
