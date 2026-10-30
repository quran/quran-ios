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

    func test_observesModifiedScrollViewInsteadOfAnEarlierHorizontalOne() throws {
        let host = host(
            VStack(spacing: 0) {
                HorizontalHeader()
                ScrollView {
                    Color.clear.frame(height: 2000)
                }
                .onScrollDragBegan {}
            }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertIdentical(observer.scrollView, try verticalScrollView(in: host.content))
    }

    func test_observesModifiedListInsteadOfAnEarlierHorizontalScrollView() throws {
        let host = host(
            VStack(spacing: 0) {
                HorizontalHeader()
                List {
                    ForEach(0 ..< 50, id: \.self) { row in
                        Text(verbatim: "Row \(row)")
                    }
                }
                .onScrollDragBegan {}
            }
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertIdentical(observer.scrollView, try verticalScrollView(in: host.content))
    }

    func test_observesScrollViewThatExtendsUnderTheSafeArea() throws {
        let host = hostWithSafeArea(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertIdentical(observer.scrollView, try verticalScrollView(in: host.content))
    }

    func test_observesListThatExtendsUnderTheSafeArea() throws {
        let host = hostWithSafeArea(
            List {
                ForEach(0 ..< 50, id: \.self) { row in
                    Text(verbatim: "Row \(row)")
                }
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertIdentical(observer.scrollView, try verticalScrollView(in: host.content))
    }

    func test_observesScrollViewInsertedAfterTheObserver() throws {
        let model = ScrollContentModel()
        let host = host(LateScrollView(model: model))
        defer { host.window.isHidden = true }
        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertNil(observer.scrollView)

        model.showsScrollView = true
        drainMainQueue()

        XCTAssertIdentical(host.content.findSubview(ofType: ScrollDragObserverView.self), observer)
        XCTAssertIdentical(observer.scrollView, try verticalScrollView(in: host.content))
    }

    func test_movesToTheReplacementScrollView() throws {
        let model = ScrollContentModel()
        let host = host(ReplacedScrollView(model: model))
        defer { host.window.isHidden = true }
        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let oldScrollView = try verticalScrollView(in: host.content)
        XCTAssertIdentical(observer.scrollView, oldScrollView)

        model.generation += 1
        drainMainQueue()

        let newScrollView = try verticalScrollView(in: host.content)
        XCTAssertNotIdentical(newScrollView, oldScrollView)
        XCTAssertIdentical(observer.scrollView, newScrollView)
    }

    func test_scrollViewsSharingTheRectAreNotObserved() throws {
        let host = host(
            ZStack {
                ScrollView {
                    Color.clear.frame(height: 2000)
                }
                ScrollView {
                    Color.clear.frame(height: 2000)
                }
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        XCTAssertEqual(host.content.findSubviews(ofType: UIScrollView.self).count, 2)
        XCTAssertNil(observer.scrollView)
    }

    func test_observesListWhoseRowHasAScrollViewTallerThanTheScreen() throws {
        let host = host(
            List {
                RowTextView(text: "A row taller than the screen")
                    .frame(height: 2000)
                    .listRowInsets(EdgeInsets())
                ForEach(0 ..< 10, id: \.self) { row in
                    Text(verbatim: "Row \(row)")
                }
            }
            .listStyle(.plain)
            .ignoresSafeArea()
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }

        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let textView = try XCTUnwrap(host.content.findSubview(ofType: UITextView.self))
        let list = try verticalScrollView(in: host.content)
        // The row's text view fills the list's rect too, so only nesting tells them apart.
        let textRect = textView.convert(textView.bounds, to: nil)
        let listRect = list.convert(list.bounds, to: nil)
        XCTAssertLessThanOrEqual(textRect.minY, listRect.minY + 1)
        XCTAssertGreaterThanOrEqual(textRect.maxY, listRect.maxY - 1)
        XCTAssertIdentical(observer.scrollView, list)
    }

    func test_sideBySidePagesEachObserveTheirOwnScrollView() {
        let host = hostWithSafeArea(
            HStack(spacing: 0) {
                ScrollView {
                    Color.clear.frame(height: 2000)
                }
                .onScrollDragBegan {}
                ScrollView {
                    Color.clear.frame(height: 2000)
                }
                .onScrollDragBegan {}
            }
        )
        defer { host.window.isHidden = true }

        let observers = host.content.findSubviews(ofType: ScrollDragObserverView.self).sorted { $0.windowMinX < $1.windowMinX }
        let scrollViews = host.content.findSubviews(ofType: UIScrollView.self).sorted { $0.windowMinX < $1.windowMinX }
        XCTAssertEqual(observers.count, 2)
        XCTAssertEqual(scrollViews.count, 2)
        for (observer, scrollView) in zip(observers, scrollViews) {
            XCTAssertIdentical(observer.scrollView, scrollView)
        }
    }

    func test_reattachesWhenLaidOutBeforeTheScrollViewMoves() throws {
        let host = host(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }
        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let scrollView = try verticalScrollView(in: host.content)
        XCTAssertIdentical(observer.scrollView, scrollView)

        // On rotation, the observer can be laid out while the scroll view still has its old frame.
        let frame = scrollView.frame
        scrollView.frame = frame.insetBy(dx: 0, dy: 100)
        observer.setNeedsLayout()
        observer.layoutIfNeeded()
        XCTAssertNil(observer.scrollView)

        scrollView.frame = frame
        drainMainQueue()

        XCTAssertIdentical(observer.scrollView, scrollView)
    }

    func test_keepsObservingAcrossARotation() throws {
        let host = host(
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .onScrollDragBegan {}
        )
        defer { host.window.isHidden = true }
        let observer = try XCTUnwrap(host.content.findSubview(ofType: ScrollDragObserverView.self))
        let scrollView = try verticalScrollView(in: host.content)

        host.window.frame = CGRect(x: 0, y: 0, width: 600, height: 400)
        host.content.frame = CGRect(x: 600, y: 0, width: 600, height: 400)
        host.window.layoutIfNeeded()
        host.content.layoutIfNeeded()
        drainMainQueue()

        XCTAssertIdentical(observer.scrollView, scrollView)
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

    private final class ScrollContentModel: ObservableObject {
        @Published var showsScrollView = false
        @Published var generation = 0
        var drags = 0
    }

    /// Starts without a scroll view and inserts one, keeping the observer's frame.
    private struct LateScrollView: View {
        @ObservedObject var model: ScrollContentModel

        var body: some View {
            ZStack {
                if model.showsScrollView {
                    ScrollView {
                        Color.clear.frame(height: 2000)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Like real callers, the action captures state, so each body update reaches the observer.
            .onScrollDragBegan { model.drags += 1 }
        }
    }

    /// Gives the scroll view a new identity, so SwiftUI replaces its backing view, on each generation.
    private struct ReplacedScrollView: View {
        @ObservedObject var model: ScrollContentModel

        var body: some View {
            ScrollView {
                Color.clear.frame(height: 2000)
            }
            .id(model.generation)
            .onScrollDragBegan { model.drags += 1 }
        }
    }

    /// A horizontal strip, before the vertical content in the view hierarchy.
    private struct HorizontalHeader: View {
        var body: some View {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0 ..< 20, id: \.self) { _ in
                        Color.blue.frame(width: 100, height: 60)
                    }
                }
            }
            .frame(height: 60)
        }
    }

    /// The scroll view that scrolls vertically, failing when there isn't exactly one.
    private func verticalScrollView(in view: UIView) throws -> UIScrollView {
        let scrollViews = view.findSubviews(ofType: UIScrollView.self).filter { $0.contentSize.height > $0.bounds.height }
        XCTAssertEqual(scrollViews.count, 1)
        return try XCTUnwrap(scrollViews.first)
    }

    /// Hosts `view` with landscape iPhone safe areas, which SwiftUI's scroll views extend under.
    private func hostWithSafeArea(_ view: some View) -> (window: UIWindow, content: UIView) {
        let controller = UIHostingController(rootView: view)
        controller.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 59, bottom: 21, right: 59)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 844, height: 390))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        window.layoutIfNeeded()
        controller.view.layoutIfNeeded()
        drainMainQueue()
        return (window, controller.view)
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
        // A cold first List can keep the main queue busy past that, so also wait for a block queued
        // now, which runs after the observer's pending update.
        var drained = false
        DispatchQueue.main.async { drained = true }
        let deadline = Date().addingTimeInterval(5)
        while !drained, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }
    }
}

extension UIView {
    fileprivate var windowMinX: CGFloat {
        convert(bounds, to: nil).minX
    }
}
