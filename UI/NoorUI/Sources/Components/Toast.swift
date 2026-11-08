//
//  Toast.swift
//
//
//  Created by Mohamed Afifi on 2024-09-22.
//

// MARK: - Toast

import Foundation
import SwiftUI
import UIKit
import UIx
import VLogging

public struct ToastAction {
    public let title: String
    public let handler: () -> Void

    public init(title: String, handler: @escaping () -> Void) {
        self.title = title
        self.handler = handler
    }
}

public struct Toast {
    // MARK: Lifecycle

    public init(
        _ message: MultipartText,
        subtitle: MultipartText? = nil,
        icon: Icon? = nil,
        action: ToastAction? = nil,
        onUserDismiss: (() -> Void)? = nil,
        duration: TimeInterval = defaultDuration,
        bottomOffset: CGFloat = 40
    ) {
        self.message = message
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.onUserDismiss = onUserDismiss
        self.duration = duration
        self.bottomOffset = bottomOffset
    }

    // MARK: Public

    public static let defaultDuration: TimeInterval = 4

    /// Identifies this toast, and its copies, to `ToastPresenter.dismissToast(withID:)`.
    public let id = UUID()

    public struct Icon {
        // MARK: Lifecycle

        /// - Parameter color: The symbol color; `nil` uses the label color. Pass one only when it carries meaning,
        ///   like a reading bookmark slot.
        public init(_ systemImage: NoorSystemImage, color: Color? = nil) {
            self.systemImage = systemImage
            self.color = color
        }

        // MARK: Internal

        let systemImage: NoorSystemImage
        let color: Color?
    }

    public let message: MultipartText
    public let subtitle: MultipartText?
    public let icon: Icon?
    public let action: ToastAction?
    /// Runs once when the user dismisses the toast with a swipe or VoiceOver's dismiss action, not when it times out or its action runs.
    public let onUserDismiss: (() -> Void)?
    public let duration: TimeInterval
    public private(set) var bottomOffset: CGFloat
}

extension Toast {
    /// How far a screen's bottom bars, like a tab bar, reach above the window's bottom edge.
    /// Only a screen that reaches the window's bottom edge has bars, and only when its bottom inset
    /// is taller than the home indicator's; a popover, even one with a down arrow, has none.
    /// A screen that stops above an opaque tab bar isn't detected, and the height is read when the
    /// toast is requested, so rotating while it shows doesn't move it.
    static func bottomBarsHeight(
        windowHeight: CGFloat,
        windowBottomInset: CGFloat,
        screenBottom: CGFloat,
        screenBottomInset: CGFloat
    ) -> CGFloat {
        guard screenBottom >= windowHeight - 0.5, screenBottomInset > windowBottomInset else {
            return 0
        }
        return screenBottomInset
    }

    /// Keeps the toast at its own offset unless bars at the bottom of the screen would cover it.
    func clearingBottomBars(height: CGFloat, spacing: CGFloat) -> Toast {
        guard height > 0 else {
            return self
        }
        var toast = self
        toast.bottomOffset = max(bottomOffset, height + spacing)
        return toast
    }
}

private class ToastHostingController: UIHostingController<ToastView> {
    init(toast: Toast, dismiss: @escaping () -> Void, userDismiss: @escaping () -> Void) {
        super.init(rootView: ToastView(toast: toast, dismiss: dismiss, userDismiss: userDismiss))
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    @objc
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class ToastContainerViewController: UIViewController {
    // MARK: Lifecycle

    init(toastViewController: UIViewController, bottomOffset: CGFloat, userDismiss: @escaping () -> Void) {
        self.toastViewController = toastViewController
        self.bottomOffset = bottomOffset
        self.userDismiss = userDismiss
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    class PassThroughView: UIView {
        // Allow touches to pass through except for the ToastView
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let hitView = super.hitTest(point, with: event)
            if hitView === self || hitView == nil {
                return nil
            }
            return hitView
        }
    }

    var dismissCompletion: (() -> Void)?

    override func loadView() {
        view = PassThroughView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Allow touches outside the toast to pass through
        view.backgroundColor = .clear

        // Add the toast view controller as a child
        addChild(toastViewController)
        view.addAutoLayoutSubview(toastViewController.view)

        // Setup constraints
        toastViewController.view.vc.horizontalEdges()
        setUpHideToastConstraints()

        toastViewController.didMove(toParent: self)

        // Add a swipe down gesture recognizer for manual dismissal
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeGesture.direction = .down
        toastViewController.view.addGestureRecognizer(swipeGesture)

        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanPanGesture(_:)))
        toastViewController.view.addGestureRecognizer(panGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showToast()
    }

    func showToast() {
        toastViewController.view.layoutIfNeeded()
        setUpShowToastConstraints()

        // Animate the toast into view
        NoorAnimation.animate {
            self.view.layoutIfNeeded()
        }
    }

    func dismissToast(completion: (() -> Void)? = nil) {
        setUpHideToastConstraints()

        // Animate the toast out of view.
        NoorAnimation.animate {
            self.view.layoutIfNeeded()
        } completion: {
            self.toastViewController.willMove(toParent: nil)
            self.toastViewController.view.removeFromSuperview()
            self.toastViewController.removeFromParent()
            self.dismiss(animated: false) {
                self.dismissCompletion?()
                completion?()
            }
        }
    }

    // MARK: Private

    private let toastViewController: UIViewController
    private let bottomOffset: CGFloat
    private let userDismiss: () -> Void

    private var activeConstraint: NSLayoutConstraint? {
        didSet {
            oldValue?.isActive = false
            activeConstraint?.isActive = true
        }
    }

    private func setUpShowToastConstraints() {
        activeConstraint = view.bottomAnchor.constraint(equalTo: toastViewController.view.bottomAnchor, constant: bottomOffset)
    }

    private func setUpHideToastConstraints() {
        activeConstraint = view.bottomAnchor.constraint(equalTo: toastViewController.view.topAnchor)
    }

    @objc
    private func handleSwipeDown() {
        userDismiss()
    }

    @objc
    private func handlePanPanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view)

        switch gesture.state {
        case .changed:
            // Move the view with the pan gesture
            if translation.y > 0 { // Allow dragging only downward
                activeConstraint?.constant = bottomOffset - translation.y
            }
        case .ended:
            if translation.y > bottomOffset {
                userDismiss()
            } else {
                showToast()
            }
        default:
            break
        }
    }
}

private class ToastWindow: UIWindow {
    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        windowLevel = UIWindow.Level.statusBar + 1
        backgroundColor = .clear
        // A new window inherits neither the app tint nor the user's appearance.
        tintColor = AppIconAccent.current.color
        overrideUserInterfaceStyle = ThemeService.shared.userInterfaceStyle
        isHidden = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Allow touches to pass through except for the ToastView
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if hitView === self || hitView == nil {
            return nil
        }
        return hitView
    }
}

@MainActor
public class ToastPresenter {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ToastPresenter()

    public func showToast(_ toast: Toast, in windowScene: UIWindowScene) {
        DispatchQueue.main.async {
            self.queue.append(toast, in: windowScene)
            self.displayNextToast()
        }
    }

    /// Dismisses the toast with `id` if it's showing, or drops it if it's waiting to show.
    public func dismissToast(withID id: UUID) {
        // Runs after the `showToast` calls before it have queued their toasts.
        DispatchQueue.main.async {
            guard self.queue.removeToast(id: id), let presentationID = self.currentToastID else { return }
            self.dismissToast(id: presentationID)
        }
    }

    // MARK: Private

    private var queue = ToastQueue<UIWindowScene>()
    private var currentToastWindow: ToastWindow?
    private var currentContainerVC: ToastContainerViewController?
    /// Identifies the showing presentation rather than its `Toast.id`, so a toast shown again
    /// can't be dismissed by its earlier presentation's timeout.
    private var currentToastID: UUID?
    private var dismissingToastID: UUID?

    private func displayNextToast() {
        guard let next = queue.showNext() else { return }
        present(toast: next.toast, in: next.scene)
    }

    private func present(toast: Toast, in windowScene: UIWindowScene) {
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
            userDismiss: { [weak self] in self?.dismissToast(id: toastID, byUser: true) }
        )

        containerVC.dismissCompletion = { [weak self] in
            self?.toastDidDismiss(id: toastID)
        }

        let toastWindow = ToastWindow(windowScene: windowScene)
        toastWindow.rootViewController = containerVC
        toastWindow.makeKeyAndVisible()

        currentToastWindow = toastWindow
        currentContainerVC = containerVC

        // Schedule automatic dismissal
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration) { [weak self] in
            self?.dismissToast(id: toastID)
        }
    }

    private func toastDidDismiss(id: UUID) {
        guard currentToastID == id else { return }
        currentToastWindow?.isHidden = true
        currentToastWindow = nil
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
    /// Shows `toast` in `view`'s window, lifted above the bars at the bottom of `view`'s screen, like a tab bar.
    ///
    /// - Parameter bottomBarsHeight: How far bars that `view`'s screen can't report through its safe area,
    ///   like a floating bar beneath a sheet, reach above the window's bottom edge.
    public func showToast(_ toast: Toast, from view: UIView, bottomBarsHeight: CGFloat = 0) {
        guard let windowScene = view.window?.windowScene else {
            logger.error("Failed to obtain windowScene")
            return
        }
        let height = max(view.bottomBarsHeight, bottomBarsHeight)
        let spacing = UIFontMetrics.default.scaledValue(for: 8, compatibleWith: view.traitCollection)
        showToast(toast.clearingBottomBars(height: height, spacing: spacing), in: windowScene)
    }
}

private extension UIView {
    /// How far the bars at the bottom of this view's screen, like a tab bar, reach above the window's bottom edge.
    var bottomBarsHeight: CGFloat {
        let screenView = sequence(first: self, next: \.superview).first { $0.next is UIViewController }
        guard let window, let screenView else {
            return 0
        }
        return Toast.bottomBarsHeight(
            windowHeight: window.bounds.height,
            windowBottomInset: window.safeAreaInsets.bottom,
            screenBottom: screenView.convert(screenView.bounds, to: window).maxY,
            screenBottomInset: screenView.safeAreaInsets.bottom
        )
    }
}
