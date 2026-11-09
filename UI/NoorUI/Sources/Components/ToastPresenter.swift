//
//  ToastPresenter.swift
//
//
//  Created by Mohamed Afifi on 2024-09-22.
//

import UIKit
import UIx
import VLogging

@MainActor
public class ToastPresenter {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ToastPresenter()

    /// Shows `toast` in `windowScene`, lifted above the bars at the bottom that keep toasts above them.
    public func showToast(_ toast: Toast, in windowScene: UIWindowScene) {
        showToast(toast, in: ToastTarget(windowScene: windowScene))
    }

    /// Dismisses the toast with `id` if it's showing, or drops it if it's waiting to show.
    public func dismissToast(withID id: UUID) {
        // Runs after the `showToast` calls before it have queued their toasts.
        DispatchQueue.main.async {
            self.queue.removeWaiting(id: id)
            guard self.queue.showing?.toast.id == id, let presentationID = self.currentToastID else { return }
            self.dismissToast(id: presentationID)
        }
    }

    // MARK: Internal

    /// Moves the showing toast, once the bars at the bottom settle, to clear them as they move, show or hide.
    func setNeedsPlacementUpdate() {
        guard currentContainerVC != nil, !isPlacementUpdateScheduled else { return }
        // Coalesces the bursts of changes a layout pass or an animation makes.
        isPlacementUpdateScheduled = true
        DispatchQueue.main.async {
            self.isPlacementUpdateScheduled = false
            self.currentContainerVC?.updatePlacement()
        }
    }

    // MARK: Private

    /// The window scene a toast shows in, and the view it shows from, whose screen's bars it clears.
    private struct ToastTarget {
        let windowScene: UIWindowScene
        weak var view: UIView?
        /// How far `view`'s screen's bars reached above the window's bottom edge when the toast was requested,
        /// for when `view` has left its window.
        var screenBarsHeight: CGFloat = 0

        /// How far `view`'s screen's bars, like a tab bar, reach above the window's bottom edge.
        @MainActor var currentScreenBarsHeight: CGFloat {
            guard let view, view.window != nil else {
                return screenBarsHeight
            }
            return view.bottomBarsHeight
        }
    }

    private var queue = ToastQueue<ToastTarget>()
    private var currentToastWindow: ToastWindow?
    private var currentContainerVC: ToastContainerViewController?
    private var isPlacementUpdateScheduled = false
    private let screenFollower = ToastScreenFollower()
    /// Identifies the showing presentation rather than its `Toast.id`, so a toast shown again
    /// can't be dismissed by its earlier presentation's timeout.
    private var currentToastID: UUID?
    private var dismissingToastID: UUID?

    private func showToast(_ toast: Toast, in target: ToastTarget) {
        DispatchQueue.main.async {
            self.queue.append(toast, to: target)
            self.displayNextToast()
        }
    }

    private func displayNextToast() {
        guard let next = queue.showNext() else { return }
        present(toast: next.toast, in: next.target)
    }

    private func present(toast: Toast, in target: ToastTarget) {
        let toastID = UUID()
        currentToastID = toastID

        let toastVC = ToastHostingController(
            toast: toast,
            dismiss: { [weak self] in self?.dismissToast(id: toastID) },
            userDismiss: { [weak self] in self?.dismissToast(id: toastID, byUser: true) }
        )

        let containerVC = ToastContainerViewController(
            toastViewController: toastVC,
            bottomOffset: toast.bottomOffset,
            placement: { [weak self] window in
                self?.bottomOffset(for: toast, from: target, in: window) ?? toast.bottomOffset
            },
            userDismiss: { [weak self] in self?.dismissToast(id: toastID, byUser: true) }
        )

        containerVC.dismissCompletion = { [weak self] in
            self?.toastDidDismiss(id: toastID)
        }

        let toastWindow = ToastWindow(windowScene: target.windowScene)
        toastWindow.rootViewController = containerVC
        toastWindow.makeKeyAndVisible()

        currentToastWindow = toastWindow
        currentContainerVC = containerVC

        // Schedule automatic dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) { [weak self] in
            self?.dismissToast(id: toastID)
        }
    }

    /// Where `toast` sits above its window's bottom edge to clear the bars at the bottom: `target`'s screen's
    /// bars, like a tab bar, and the bars that keep toasts above them, like the reader's audio bar.
    private func bottomOffset(for toast: Toast, from target: ToastTarget, in window: UIWindow) -> CGFloat {
        let snapshot = ToastAvoidingBars.snapshot(in: window)
        // The screen showing the toast can be sliding in or out, like an editor closing after saving.
        let shownFrom = target.view?.nearestViewController.map { [$0] } ?? []
        screenFollower.followTransitions(of: snapshot.barScreens + snapshot.screensAbove + shownFrom)
        screenFollower.followViews(of: snapshot.screensAbove + shownFrom)
        let placement = ToastPlacement(
            windowSize: window.bounds.size,
            windowSafeAreaInsets: window.safeAreaInsets,
            screenBarsHeight: target.currentScreenBarsHeight,
            bars: snapshot.bars
        )
        let spacing = UIFontMetrics.default.scaledValue(for: 8, compatibleWith: window.traitCollection)
        return placement.bottomOffset(toastOffset: toast.bottomOffset, spacing: spacing)
    }

    private func toastDidDismiss(id: UUID) {
        guard currentToastID == id else { return }
        currentToastWindow?.isHidden = true
        currentToastWindow = nil
        screenFollower.stop()
        currentContainerVC = nil
        currentToastID = nil
        queue.removeShowing()
        displayNextToast()
    }

    /// Dismisses the toast once, however many of its swipe, VoiceOver dismiss, action and timeout ask to.
    private func dismissToast(id: UUID, byUser: Bool = false) {
        DispatchQueue.main.async {
            guard self.currentToastID == id, self.dismissingToastID != id else { return }
            self.dismissingToastID = id
            if byUser {
                self.queue.showing?.toast.onUserDismiss?()
            }
            self.currentContainerVC?.dismissToast()
        }
    }
}

extension ToastPresenter {
    /// Shows `toast` in `view`'s window, lifted above the bars at the bottom of `view`'s screen, like a tab bar,
    /// and the bars that keep toasts above them, like the reader's audio bar.
    public func showToast(_ toast: Toast, from view: UIView) {
        guard let windowScene = view.window?.windowScene else {
            logger.error("Failed to obtain windowScene")
            return
        }
        let target = ToastTarget(windowScene: windowScene, view: view, screenBarsHeight: view.bottomBarsHeight)
        showToast(toast, in: target)
    }
}

private extension UIView {
    /// How far the bars at the bottom of this view's screen, like a tab bar, reach above the window's bottom edge.
    var bottomBarsHeight: CGFloat {
        let screenView = sequence(first: self, next: \.superview).first { $0.next is UIViewController }
        guard let window, let screenView else {
            return 0
        }
        return ToastPlacement.screenBarsHeight(
            windowHeight: window.bounds.height,
            windowBottomInset: window.safeAreaInsets.bottom,
            screenBottom: screenView.convert(screenView.bounds, to: window).maxY,
            screenBottomInset: screenView.safeAreaInsets.bottom
        )
    }
}
