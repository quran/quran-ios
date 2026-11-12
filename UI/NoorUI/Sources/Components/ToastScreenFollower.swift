//
//  ToastScreenFollower.swift
//
//
//  Created by Mohamed Afifi on 2026-11-08.
//

import UIKit

/// Follows the screens around the bars while a toast shows, so it moves when a screen above a bar slides in
/// or out, changes detent, or closes. UIKit tells the bars under a screen none of that.
@MainActor
final class ToastScreenFollower {
    // MARK: Internal

    /// Moves the toast when any of `screens` finishes sliding in or out, until `stop()`.
    func followTransitions(of screens: [UIViewController]) {
        for screen in screens {
            followTransition(of: screen)
        }
    }

    /// Moves the toast when any of `screens` resizes, like a sheet changing detent, or closes, until `stop()`.
    func followViews(of screens: [UIViewController]) {
        for screen in screens {
            if let view = screen.viewIfLoaded, view.window != nil {
                observe(view)
            }
        }
    }

    /// Stops following the screens, once the toast is gone.
    func stop() {
        for observer in observers.allObjects {
            observer.removeFromSuperview()
        }
        observers.removeAllObjects()
        coordinators.removeAllObjects()
    }

    // MARK: Private

    private let observers = NSHashTable<ToastScreenObserver>.weakObjects()
    private let coordinators = NSHashTable<AnyObject>.weakObjects()

    /// A screen sliding in or out sets its final frame at the transition's start, but whether it covers a bar,
    /// or is still there at all, is only settled when the transition ends.
    private func followTransition(of screen: UIViewController) {
        guard let coordinator = screen.transitionCoordinator, !coordinators.contains(coordinator) else {
            return
        }
        coordinators.add(coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            ToastPresenter.shared.setNeedsPlacementUpdate()
        }
    }

    private func observe(_ view: UIView) {
        guard !view.subviews.contains(where: { $0 is ToastScreenObserver }) else {
            return
        }
        let observer = ToastScreenObserver()
        view.addSubview(observer)
        observers.add(observer)
    }
}

/// A hidden subview that reports when its screen's view resizes, like a sheet changing detent, or leaves
/// its window, like a sheet that closed. Unlike a bar's tracker, it doesn't keep toasts above the screen.
private final class ToastScreenObserver: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
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
        observations = superview.map(observeScreenLayer) ?? []
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        ToastPresenter.shared.setNeedsPlacementUpdate()
    }

    // MARK: Private

    private var observations: [NSKeyValueObservation] = []

    private func observeScreenLayer(_ screen: UIView) -> [NSKeyValueObservation] {
        let layer = screen.layer
        return [
            layer.observe(\.position) { _, _ in Self.screenLayerDidChange() },
            layer.observe(\.bounds) { _, _ in Self.screenLayerDidChange() },
        ]
    }

    private nonisolated static func screenLayerDidChange() {
        ToastAvoidingBars.layerDidChange()
    }
}
