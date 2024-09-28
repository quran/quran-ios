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

public struct ToastAction {
    public let title: String
    public let handler: () -> Void

    public init(title: String, handler: @escaping () -> Void) {
        self.title = title
        self.handler = handler
    }
}

public struct Toast {
    public let message: String
    public let action: ToastAction?
    public let duration: TimeInterval
    public let bottomOffset: CGFloat

    public init(
        _ message: String,
        action: ToastAction? = nil,
        duration: TimeInterval = 4.0,
        bottomOffset: CGFloat = 40
    ) {
        self.message = message
        self.action = action
        self.duration = duration
        self.bottomOffset = bottomOffset
    }
}

private struct ToastView: View {
    let message: String
    let action: ToastAction?
    let dismiss: () -> Void
    @ScaledMetric var shadowRadius = 5

    var body: some View {
        HStack {
            Text(message)
                .foregroundColor(.systemBackground)
            Spacer()
            if let action {
                Button(action.title) {
                    action.handler()
                    dismiss()
                }
                .foregroundColor(.systemBackground)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.label.opacity(0.8))
                .shadow(color: .label.opacity(0.33), radius: shadowRadius)
        )
        .padding(.horizontal)
    }
}

private class ToastHostingController: UIHostingController<ToastView> {
    init(toast: Toast, dismiss: @escaping () -> Void) {
        let rootView = ToastView(
            message: toast.message,
            action: toast.action,
            dismiss: dismiss
        )
        super.init(rootView: rootView)
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
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0) {
            self.view.layoutIfNeeded()
        }
    }

    func dismissToast(completion: (() -> Void)? = nil) {
        setUpHideToastConstraints()

        // Animate the toast into view
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.toastViewController.willMove(toParent: nil)
            self.toastViewController.view.removeFromSuperview()
            self.toastViewController.removeFromParent()
            self.dismiss(animated: false) {
                self.dismissCompletion?()
                completion?()
            }
        })
    }

    // MARK: Private

    private let toastViewController: UIViewController
    private let bottomOffset: CGFloat
    private let animationDuration: CGFloat = 0.3

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

#Preview {
    VStack {
        Spacer()
        ToastView(
            message: "This is a toast message",
            action: ToastAction(title: "Dismiss", handler: {}),
            dismiss: {}
        )
        .padding(.bottom, 40)
    }
}
