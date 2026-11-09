//
//  ToastAvoidingBars.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import SwiftUI
import UIKit

extension UIView {
    /// Keeps toasts above this view while it shows, like a floating bar at the bottom of the screen.
    ///
    /// A showing toast follows the view as it moves, resizes, shows or hides. It ignores the view while
    /// a sheet presented above the view's screen covers it. Standard tab bars and toolbars need nothing:
    /// toasts clear them through the presenting screen's safe area.
    public var keepsToastsAbove: Bool {
        get { toastAvoidingBarTracker != nil }
        set {
            if newValue {
                guard toastAvoidingBarTracker == nil else { return }
                let tracker = ToastAvoidingBarTracker(frame: bounds)
                tracker.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                addSubview(tracker)
            } else {
                toastAvoidingBarTracker?.removeFromSuperview()
            }
        }
    }

    private var toastAvoidingBarTracker: ToastAvoidingBarTracker? {
        subviews.lazy.compactMap { $0 as? ToastAvoidingBarTracker }.first
    }
}

extension View {
    /// Keeps toasts above this view while it shows, like a floating button pinned to the bottom of a sheet.
    ///
    /// A showing toast follows the view as it moves, resizes, shows or hides. It ignores the view while
    /// a sheet presented above the view's screen covers it. Standard tab bars and toolbars need nothing:
    /// toasts clear them through the presenting screen's safe area.
    public func keepsToastsAbove() -> some View {
        background(
            GeometryReader { proxy in
                ToastAvoidingBarReader(frame: proxy.frame(in: .global))
            }
        )
    }
}

/// The views that keep toasts above them, which tell the showing toast when they change.
@MainActor
enum ToastAvoidingBars {
    // MARK: Internal

    /// The bars in `window`'s scene, with their frames and the screens presented above them in `window`'s coordinates.
    static func placementBars(in window: UIWindow) -> [ToastPlacement.Bar] {
        trackers.allObjects.compactMap { tracker in
            guard let bar = tracker.superview,
                  let barWindow = bar.window,
                  !(barWindow is ToastWindow),
                  barWindow.windowScene === window.windowScene
            else {
                return nil
            }
            return ToastPlacement.Bar(
                frame: frame(of: bar, in: window),
                isVisible: bar.showsOnScreen && !bar.isInScreenBeingDismissed,
                screensAbove: bar.screensPresentedAbove.map { frame(of: $0, in: window) }
            )
        }
    }

    /// Asks the showing toast, if any, to move to clear the bars.
    static func barsDidChange() {
        ToastPresenter.shared.setNeedsPlacementUpdate()
    }

    // MARK: Fileprivate

    fileprivate static let trackers = NSHashTable<ToastAvoidingBarTracker>.weakObjects()

    // MARK: Private

    private static func frame(of view: UIView, in window: UIWindow) -> CGRect {
        guard let viewWindow = view.window else {
            return .null
        }
        return viewWindow.convert(view.convert(view.bounds, to: viewWindow), to: window)
    }
}

/// A hidden subview that marks its superview as a bar that keeps toasts above it, and reports the bar's changes.
private final class ToastAvoidingBarTracker: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        observations = superview.map(observeBarLayer) ?? []
        if superview == nil {
            ToastAvoidingBars.trackers.remove(self)
        } else {
            ToastAvoidingBars.trackers.add(self)
        }
        ToastAvoidingBars.barsDidChange()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ToastAvoidingBars.barsDidChange()
    }

    // MARK: Private

    private var observations: [NSKeyValueObservation] = []

    /// Moving, resizing, hiding or fading the bar changes its layer.
    private func observeBarLayer(_ bar: UIView) -> [NSKeyValueObservation] {
        let layer = bar.layer
        return [
            layer.observe(\.position) { _, _ in Self.barLayerDidChange() },
            layer.observe(\.bounds) { _, _ in Self.barLayerDidChange() },
            layer.observe(\.transform) { _, _ in Self.barLayerDidChange() },
            layer.observe(\.isHidden) { _, _ in Self.barLayerDidChange() },
            layer.observe(\.opacity) { _, _ in Self.barLayerDidChange() },
        ]
    }

    private nonisolated static func barLayerDidChange() {
        // UIKit changes the layer, and calls its observers, on the main thread.
        MainActor.assumeIsolated {
            ToastAvoidingBars.barsDidChange()
        }
    }
}

/// Marks the SwiftUI view it's the background of as a bar, and reports its moves within the hosting view.
private struct ToastAvoidingBarReader: UIViewRepresentable {
    /// Read so SwiftUI updates the reader, and the showing toast, when the bar moves.
    let frame: CGRect

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.keepsToastsAbove = true
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        ToastAvoidingBars.barsDidChange()
    }
}

private extension UIView {
    /// Whether this view and every view it's in show.
    var showsOnScreen: Bool {
        sequence(first: self, next: \.superview).allSatisfy { !$0.isHidden && $0.alpha > 0.01 }
    }

    /// The screen this view is in, like a `UIHostingController` or the screen it's a child of.
    var owningViewController: UIViewController? {
        sequence(first: self as UIResponder, next: \.next).lazy.compactMap { $0 as? UIViewController }.first
    }

    /// Whether the screen this view is in is closing.
    var isInScreenBeingDismissed: Bool {
        guard let owningViewController else {
            return false
        }
        return sequence(first: owningViewController, next: \.parent).contains { $0.isBeingDismissed }
    }

    /// The views of the screens presented above this view's screen that show, closest first.
    /// A screen being dismissed is closing, along with the screens above it.
    var screensPresentedAbove: [UIView] {
        guard let owningViewController else {
            return []
        }
        let presenter = sequence(first: owningViewController, next: \.parent).first { $0.presentedViewController != nil }
        var views: [UIView] = []
        var presented = presenter?.presentedViewController
        while let screen = presented, !screen.isBeingDismissed {
            if let view = screen.viewIfLoaded, view.window != nil {
                views.append(view)
            }
            presented = screen.presentedViewController
        }
        return views
    }
}
