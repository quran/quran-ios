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
    }
}

/// Watches the pan gesture of the scroll view next to it in the SwiftUI hierarchy.
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
        observeScrollView()
        // SwiftUI can insert the scroll view after its background.
        DispatchQueue.main.async { [weak self] in
            self?.observeScrollView()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        observeScrollView()
    }

    @objc
    func panGestureChanged(_ gesture: UIPanGestureRecognizer) {
        // Content that fits still bounces before iOS 16.4's `scrollBounceBehavior(.basedOnSize)`.
        if gesture.state == .began, let scrollView, scrollView.canScrollContentVertically {
            action()
        }
    }

    // MARK: Private

    private func observeScrollView() {
        if let scrollView, scrollView.window != nil, scrollView.window === window {
            return
        }
        let newScrollView = window == nil ? nil : siblingScrollView()
        guard newScrollView !== scrollView else {
            return
        }
        scrollView?.panGestureRecognizer.removeTarget(self, action: #selector(panGestureChanged(_:)))
        newScrollView?.panGestureRecognizer.addTarget(self, action: #selector(panGestureChanged(_:)))
        scrollView = newScrollView
    }

    /// The outermost scroll view under the closest ancestor that has one.
    ///
    /// The observer is the scrolling view's background, so the scroll view is a sibling rather
    /// than an ancestor. The search stops at the hosting view controller's root view, so it never
    /// reaches a container scroll view, such as a page view controller's.
    private func siblingScrollView() -> UIScrollView? {
        let rootView = nearestViewController?.view
        var ancestor = superview
        while let container = ancestor {
            if let scrollView = container.outermostScrollView(excluding: self) {
                return scrollView
            }
            if container === rootView {
                return nil
            }
            ancestor = container.superview
        }
        return nil
    }
}

private extension UIScrollView {
    var canScrollContentVertically: Bool {
        contentSize.height > bounds.height - adjustedContentInset.top - adjustedContentInset.bottom
    }
}

private extension UIView {
    func outermostScrollView(excluding excludedView: UIView) -> UIScrollView? {
        // Breadth-first, so nested scroll views, like text views in list cells, come later.
        var queue = subviews[...]
        while let view = queue.popFirst() {
            if view === excludedView {
                continue
            }
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            queue.append(contentsOf: view.subviews)
        }
        return nil
    }
}
