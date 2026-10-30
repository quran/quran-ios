//
//  ScrollDragObserver.swift
//
//
//  Created by Mohamed Afifi on 2026-10-30.
//

import SwiftUI
import UIKit

extension View {
    /// Calls `action` when the user starts a drag that can scroll the vertical `ScrollView` or `List`
    /// this modifier is applied to.
    ///
    /// A drag on content that fits, which only bounces, doesn't call it. Neither do scrolls without the
    /// scroll view's pan gesture: programmatic ones such as `ScrollViewProxy.scrollTo`, VoiceOver and
    /// keyboard scrolling, or a status-bar tap.
    public func onScrollDragBegan(perform action: @escaping () -> Void) -> some View {
        background(
            ScrollDragObserver(action: action)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
        )
    }
}

private struct ScrollDragObserver: UIViewRepresentable {
    let action: () -> Void

    func makeUIView(context: Context) -> ScrollDragObserverView {
        ScrollDragObserverView(action: action)
    }

    func updateUIView(_ view: ScrollDragObserverView, context: Context) {
        view.action = action
        // SwiftUI may have inserted or replaced the scroll view. It usually calls this on each body
        // update because the action's captured context changes, though that's undocumented; layout
        // and window changes remain the fallback.
        view.setNeedsScrollViewUpdate()
    }
}

/// Watches the pan gesture of the scroll view that the observer is the background of.
///
/// Adding a target to the pan gesture doesn't change how the scroll view scrolls,
/// unlike a SwiftUI drag gesture on the scrolling content.
final class ScrollDragObserverView: UIView {
    // MARK: Lifecycle

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(frame: .zero)
        isHidden = true
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    var action: () -> Void
    private(set) weak var scrollView: UIScrollView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Leaving the window stops observing, so a released observer is never a gesture target.
        updateScrollViewOrRetry()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateScrollViewOrRetry()
    }

    /// Updates the observed scroll view on the next main-queue turn, once SwiftUI has placed its views.
    func setNeedsScrollViewUpdate() {
        guard !isScrollViewUpdateScheduled else {
            return
        }
        isScrollViewUpdateScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.isScrollViewUpdateScheduled = false
            self?.updateScrollView()
        }
    }

    @objc
    func panGestureChanged(_ gesture: UIPanGestureRecognizer) {
        // Content that fits still bounces before iOS 16.4's `scrollBounceBehavior(.basedOnSize)`.
        if gesture.state == .began, let scrollView, scrollView.canScrollContentVertically {
            action()
        }
    }

    // MARK: Private

    private var isScrollViewUpdateScheduled = false

    private func updateScrollViewOrRetry() {
        // SwiftUI can insert or lay out the scroll view after its background, such as moving it after
        // the observer on rotation, so a search that finds nothing waits for the next turn.
        if scrollView != nil || window == nil {
            updateScrollView()
        }
        if scrollView == nil, window != nil {
            setNeedsScrollViewUpdate()
        }
    }

    private func updateScrollView() {
        let rootView = window == nil ? nil : nearestViewController?.view
        // A cheap check keeps the current scroll view; the full search runs only when it stops matching.
        if let scrollView, let rootView, occupiesObserverRect(scrollView, in: rootView) {
            return
        }
        let newScrollView = rootView.flatMap(matchingScrollView(in:))
        guard newScrollView !== scrollView else {
            return
        }
        scrollView?.panGestureRecognizer.removeTarget(self, action: #selector(panGestureChanged(_:)))
        newScrollView?.panGestureRecognizer.addTarget(self, action: #selector(panGestureChanged(_:)))
        scrollView = newScrollView
    }

    /// The only scroll view in the hosting controller's view that occupies the observer's rect.
    ///
    /// The observer is the background of the scrolling view, so they share a rect. Searching only the
    /// hosting controller's view keeps out a container scroll view, such as a page view controller's,
    /// which can be as large as a full-screen page.
    private func matchingScrollView(in rootView: UIView) -> UIScrollView? {
        var match: UIScrollView?
        // Breadth-first, so a scroll view comes before the ones nested in its content.
        var queue = rootView.subviews
        var index = 0
        while index < queue.count {
            let view = queue[index]
            index += 1
            if let scrollView = view as? UIScrollView, occupiesObserverRect(scrollView, in: rootView) {
                // Two scroll views in one rect are ambiguous, so observe neither rather than guess.
                if match != nil {
                    return nil
                }
                match = scrollView
                // Its content can also fill the rect, like a text view in a row taller than the screen.
                continue
            }
            queue.append(contentsOf: view.subviews)
        }
        return match
    }

    /// Whether `scrollView` occupies the observer's rect, compared within the root view's safe area.
    ///
    /// The frames rarely match exactly. The scroll view extends under the safe area that the observer
    /// respects and insets its content instead: vertically on iOS 17, in both axes from iOS 18. Within
    /// the safe area it then has the observer's top and bottom, but it can be narrower when its content
    /// is, such as an image that fits the height.
    private func occupiesObserverRect(_ scrollView: UIScrollView, in rootView: UIView) -> Bool {
        guard let window, scrollView.window === window else {
            return false
        }
        let safeRect = rootView.convert(rootView.bounds.inset(by: rootView.safeAreaInsets), to: nil)
        let observerRect = convert(bounds, to: nil).intersection(safeRect)
        let scrollRect = scrollView.convert(scrollView.bounds, to: nil).intersection(safeRect)
        guard !observerRect.isEmpty, !scrollRect.isEmpty else {
            return false
        }
        let tolerance: CGFloat = 1
        return abs(scrollRect.minY - observerRect.minY) <= tolerance
            && abs(scrollRect.maxY - observerRect.maxY) <= tolerance
            && scrollRect.minX >= observerRect.minX - tolerance
            && scrollRect.maxX <= observerRect.maxX + tolerance
    }
}

private extension UIScrollView {
    var canScrollContentVertically: Bool {
        contentSize.height > bounds.height - adjustedContentInset.top - adjustedContentInset.bottom
    }
}
