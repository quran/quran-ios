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

public struct Toast {
    // MARK: Lifecycle

    public init(
        _ message: MultipartText,
        subtitle: MultipartText? = nil,
        icon: Icon? = nil,
        action: ToastAction? = nil,
        duration: TimeInterval = defaultDuration,
        bottomOffset: CGFloat = 40
    ) {
        self.message = message
        self.subtitle = subtitle
        self.icon = icon
        self.action = action
        self.duration = duration
        self.bottomOffset = bottomOffset
    }

    // MARK: Public

    public static let defaultDuration: TimeInterval = 4

    public struct Icon {
        // MARK: Lifecycle

        /// - Parameter color: The glyph and tile color; `nil` uses the app tint.
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
    init(toast: Toast, dismiss: @escaping () -> Void) {
        super.init(rootView: ToastView(toast: toast, dismiss: dismiss))
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

    init(toastViewController: UIViewController, bottomOffset: CGFloat) {
        self.toastViewController = toastViewController
        self.bottomOffset = bottomOffset
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
        dismissToast()
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
                dismissToast()
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
            self.queue.append((toast: toast, windowScene: windowScene))
            self.displayNextToast()
        }
    }

    public func dismissCurrentToast() {
        guard let id = currentToastID else { return }
        dismissToast(id: id)
    }

    // MARK: Private

    private var queue: [(toast: Toast, windowScene: UIWindowScene)] = []
    private var isShowing = false
    private var currentToastWindow: ToastWindow?
    private var currentContainerVC: ToastContainerViewController?
    private var currentToastID: UUID?

    private func displayNextToast() {
        guard !isShowing, let nextToast = queue.first else { return }
        isShowing = true
        present(toast: nextToast.toast, in: nextToast.windowScene)
    }

    private func present(toast: Toast, in windowScene: UIWindowScene) {
        let toastID = UUID()
        currentToastID = toastID

        let toastVC = ToastHostingController(toast: toast, dismiss: { [weak self] in
            self?.dismissToast(id: toastID)
        })

        let containerVC = ToastContainerViewController(
            toastViewController: toastVC,
            bottomOffset: toast.bottomOffset
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
        isShowing = false
        queue.removeFirst()
        displayNextToast()
    }

    private func dismissToast(id: UUID) {
        DispatchQueue.main.async {
            guard self.currentToastID == id else { return }
            self.currentContainerVC?.dismissToast()
        }
    }
}
