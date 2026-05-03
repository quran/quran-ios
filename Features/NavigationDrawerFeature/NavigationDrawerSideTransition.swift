//
//  NavigationDrawerSideTransition.swift
//  Quran
//
//  Created by Abdirizak Hassan on 4/25/26.
//  Copyright © 2026 Quran.com. All rights reserved.
//

import UIKit

/// Transitioning delegate that wires up the side-drawer presentation controller
/// and its slide-in / slide-out animators.
final class NavigationDrawerSideTransition: NSObject, UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        NavigationDrawerSidePresentationController(presentedViewController: presented, presenting: presenting)
    }

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        NavigationDrawerSideAnimator(isPresenting: true)
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        NavigationDrawerSideAnimator(isPresenting: false)
    }
}

/// Slides the drawer in from / out to the trailing edge.
final class NavigationDrawerSideAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let isPresenting: Bool

    init(isPresenting: Bool) {
        self.isPresenting = isPresenting
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.28
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let containerView = transitionContext.containerView
        let isRTL = containerView.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let duration = transitionDuration(using: transitionContext)

        if isPresenting {
            guard let toView = transitionContext.view(forKey: .to),
                  let toVC = transitionContext.viewController(forKey: .to)
            else {
                transitionContext.completeTransition(false)
                return
            }
            let finalFrame = transitionContext.finalFrame(for: toVC)
            toView.frame = finalFrame
            // Slide in from outside the trailing edge
            let offscreenX: CGFloat = isRTL ? -finalFrame.width : containerView.bounds.width
            toView.transform = CGAffineTransform(translationX: offscreenX - finalFrame.origin.x, y: 0)
            containerView.addSubview(toView)

            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseOut],
                animations: {
                    toView.transform = .identity
                },
                completion: { finished in
                    transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
                }
            )
        } else {
            guard let fromView = transitionContext.view(forKey: .from) else {
                transitionContext.completeTransition(false)
                return
            }
            let frame = fromView.frame
            let offscreenX: CGFloat = isRTL ? -frame.width : containerView.bounds.width

            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: [.curveEaseIn],
                animations: {
                    fromView.transform = CGAffineTransform(translationX: offscreenX - frame.origin.x, y: 0)
                },
                completion: { finished in
                    fromView.transform = .identity
                    transitionContext.completeTransition(finished && !transitionContext.transitionWasCancelled)
                }
            )
        }
    }
}
