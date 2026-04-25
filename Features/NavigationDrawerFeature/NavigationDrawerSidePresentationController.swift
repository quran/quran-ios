//
//  NavigationDrawerSidePresentationController.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import UIKit

/// Presents the drawer as a side sheet anchored to the trailing edge of the
/// containing window. In LTR locales the drawer slides in from the right; in
/// RTL it slides in from the left. A dim view sits behind it and dismisses
/// the drawer on tap.
final class NavigationDrawerSidePresentationController: UIPresentationController {
    // MARK: - Constants

    /// Fraction of the container width occupied by the drawer.
    private static let widthFraction: CGFloat = 0.84
    /// Hard cap on drawer width for tablets and large devices.
    private static let maxWidth: CGFloat = 380

    // MARK: - Subviews

    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleDimTap))
        view.addGestureRecognizer(tap)
        view.accessibilityIdentifier = "NavigationDrawerDimmingView"
        return view
    }()

    // MARK: - Frames

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView else { return .zero }
        let bounds = containerView.bounds
        let width = min(bounds.width * Self.widthFraction, Self.maxWidth)
        let isRTL = containerView.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let originX = isRTL ? 0 : bounds.width - width
        return CGRect(x: originX, y: 0, width: width, height: bounds.height)
    }

    // MARK: - Presentation lifecycle

    override func presentationTransitionWillBegin() {
        super.presentationTransitionWillBegin()
        guard let containerView else { return }

        dimmingView.frame = containerView.bounds
        dimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.insertSubview(dimmingView, at: 0)

        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmingView.alpha = 1
            })
        } else {
            dimmingView.alpha = 1
        }
    }

    override func dismissalTransitionWillBegin() {
        super.dismissalTransitionWillBegin()
        if let coordinator = presentingViewController.transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dimmingView.alpha = 0
            })
        } else {
            dimmingView.alpha = 0
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        if completed {
            dimmingView.removeFromSuperview()
        }
    }

    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    // MARK: - Actions

    @objc
    private func handleDimTap() {
        presentedViewController.dismiss(animated: true)
    }
}
