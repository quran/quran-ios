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

public struct ToastAction {
    public let title: String
    public let handler: () -> Void

    public init(title: String, handler: @escaping () -> Void) {
        self.title = title
        self.handler = handler
    }
}

public struct Toast: Identifiable {
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

    /// Identifies this toast, and its copies, to `ToastPresenter.dismissToast(withID:)`.
    public let id = UUID()
    public let message: MultipartText
    public let subtitle: MultipartText?
    public let icon: Icon?
    public let action: ToastAction?
    /// Runs once when the user dismisses the toast with a swipe or VoiceOver's dismiss action, not when it times out or its action runs.
    public let onUserDismiss: (() -> Void)?
    public let duration: TimeInterval
    /// How far the toast sits above the window's bottom edge, unless it's raised to clear the bars at the bottom.
    public let bottomOffset: CGFloat
}

extension Toast {
    /// How far a screen's bottom bars, like a tab bar, reach above the window's bottom edge.
    /// Only a screen that reaches the window's bottom edge has bars, and only when its bottom inset
    /// is taller than the home indicator's; a popover, even one with a down arrow, has none.
    /// A screen that stops above an opaque tab bar isn't detected. Bars a screen can't report through its
    /// safe area, like the reader's audio bar, keep toasts above them with `keepsToastsAbove`.
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
}

final class ToastHostingController: UIHostingController<ToastView> {
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

final class ToastContainerViewController: UIViewController {
    // MARK: Lifecycle

    /// - Parameter bottomOffset: Where the toast sits above the window's bottom edge, read when it shows
    ///   and whenever the bars it clears change.
    init(
        toastViewController: UIViewController,
        bottomOffset: @escaping () -> CGFloat,
        userDismiss: @escaping () -> Void
    ) {
        self.toastViewController = toastViewController
        resolveBottomOffset = bottomOffset
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
        bottomOffset = resolveBottomOffset()
        isShown = true
        toastViewController.view.layoutIfNeeded()
        setUpShowToastConstraints()

        // Animate the toast into view
        NoorAnimation.animate {
            self.view.layoutIfNeeded()
        }
    }

    /// Moves the shown toast to clear the bars at the bottom as they move, show or hide.
    func updatePlacement() {
        guard isShown else {
            return
        }
        let offset = resolveBottomOffset()
        guard abs(offset - bottomOffset) > 0.5 else {
            return
        }
        bottomOffset = offset
        // A drag moves the toast from the new offset when it next changes.
        guard !isDragging else {
            return
        }
        activeConstraint?.constant = offset
        NoorAnimation.animate {
            self.view.layoutIfNeeded()
        }
    }

    func dismissToast(completion: (() -> Void)? = nil) {
        isShown = false
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
    private let resolveBottomOffset: () -> CGFloat
    private let userDismiss: () -> Void
    private var bottomOffset: CGFloat = 0
    /// Whether the toast is on screen, from when it starts showing until it starts dismissing.
    private var isShown = false
    private var isDragging = false

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
            isDragging = true
            // Move the view with the pan gesture
            if translation.y > 0 { // Allow dragging only downward
                activeConstraint?.constant = bottomOffset - translation.y
            }
        case .ended:
            isDragging = false
            if translation.y > bottomOffset {
                userDismiss()
            } else {
                showToast()
            }
        case .cancelled, .failed:
            isDragging = false
            if isShown {
                showToast()
            }
        default:
            break
        }
    }
}

final class ToastWindow: UIWindow {
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
