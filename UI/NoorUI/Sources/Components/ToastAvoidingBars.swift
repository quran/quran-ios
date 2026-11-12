//
//  ToastAvoidingBars.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import SwiftUI
import UIKit
import UIx

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

    /// The bars in a window's scene, and the screens a showing toast follows to move when they change.
    struct Snapshot {
        /// The bars, with their frames and the screens presented above them in the window's coordinates.
        var bars: [ToastPlacement.Bar] = []
        /// The screens the bars are in.
        var barScreens: [UIViewController] = []
        /// The screens presented above the bars, including those still presenting or dismissing.
        /// UIKit doesn't tell the bars when a screen above them slides in or out, changes detent, or closes.
        var screensAbove: [UIViewController] = []
    }

    /// The bars in `window`'s scene, in `window`'s coordinates.
    static func snapshot(in window: UIWindow) -> Snapshot {
        var snapshot = Snapshot()
        for tracker in trackers.allObjects {
            guard let bar = tracker.superview,
                  let barWindow = bar.window,
                  !(barWindow is ToastWindow),
                  barWindow.windowScene === window.windowScene
            else {
                continue
            }
            let owner = bar.nearestViewController
            let presented = owner?.presentedScreens ?? []
            // A screen being dismissed is closing, along with the screens above it.
            let showing = presented.prefix { !$0.isBeingDismissed }
            snapshot.bars.append(ToastPlacement.Bar(
                frame: frame(of: bar, in: window),
                isVisible: bar.showsOnScreen && !(owner?.isBeingDismissedWithParents ?? false),
                screensAbove: showing.compactMap(\.viewIfLoaded)
                    .filter { $0.window != nil }
                    .map { frame(of: $0, in: window) }
            ))
            snapshot.barScreens += owner.map { [$0] } ?? []
            snapshot.screensAbove += presented
        }
        return snapshot
    }

    /// Asks the showing toast, if any, to move to clear the bars.
    static func barsDidChange() {
        ToastPresenter.shared.setNeedsPlacementUpdate()
    }

    /// Reports a change to a bar's layer, or a screen's, from key-value observing, which runs on the thread
    /// that changed the layer.
    nonisolated static func layerDidChange() {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                MainActor.assumeIsolated {
                    barsDidChange()
                }
            }
            return
        }
        MainActor.assumeIsolated {
            barsDidChange()
        }
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

    /// UIKit dims the tint of the screens under a sheet, and restores it when the sheet closes, the only
    /// sign the bar gets that a screen was presented above it.
    override func tintColorDidChange() {
        super.tintColorDidChange()
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
        ToastAvoidingBars.layerDidChange()
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
}

private extension UIViewController {
    /// Whether this screen, or the screen it's in, is closing.
    var isBeingDismissedWithParents: Bool {
        sequence(first: self, next: \.parent).contains { $0.isBeingDismissed }
    }

    /// The screens presented above this one, closest first.
    var presentedScreens: [UIViewController] {
        let presenter = sequence(first: self, next: \.parent).first { $0.presentedViewController != nil }
        var screens: [UIViewController] = []
        var presented = presenter?.presentedViewController
        while let screen = presented {
            screens.append(screen)
            presented = screen.presentedViewController
        }
        return screens
    }
}
