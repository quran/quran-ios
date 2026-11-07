//
//  UIViewController+Extensions.swift
//  Bday
//
//  Created by Mohamed Afifi on 1/15/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import UIKit
import VLogging

public extension UIViewController {
    func addFullScreenChild(_ viewController: UIViewController) {
        addChild(viewController)
        view.addAutoLayoutSubview(viewController.view)
        viewController.view.vc.edges()
        viewController.didMove(toParent: self)
    }

    func removeSelfFromParentIfNeeded() {
        if parent == nil {
            return
        }
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
        didMove(toParent: nil)
    }

    func removeChild(_ viewController: UIViewController) {
        viewController.removeSelfFromParentIfNeeded()
    }

    /// Rotates an iPhone window to portrait. Call it once the view is in a window.
    func rotateToPortraitIfPhone() {
        if traitCollection.userInterfaceIdiom == .phone {
            requestInterfaceOrientations(.portrait)
        }
    }

    /// Asks the window to rotate to one of `orientations`, after `supportedInterfaceOrientations` changes.
    ///
    /// Does nothing in windows that are regular in both size classes, like the unfolded iPhone Duo's
    /// inner display, because they resize instead of rotating and ignore supported orientations.
    func requestInterfaceOrientations(_ orientations: UIInterfaceOrientationMask) {
        let traits = view.window?.traitCollection ?? traitCollection
        if traits.horizontalSizeClass == .regular, traits.verticalSizeClass == .regular {
            return
        }
        if #available(iOS 16.0, *) {
            setNeedsUpdateOfSupportedInterfaceOrientations()
            view.window?.windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: orientations)) { error in
                logger.error("Failed to rotate to orientations \(orientations.rawValue). Error: \(error)")
            }
        } else if let orientation = orientations.preferredOrientation {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }

    func setPreferredContentSize(to controller: UIViewController, min minSize: CGSize, max maxSize: CGSize) {
        let size = controller.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
        let width = min(maxSize.width, max(minSize.width, size.width))
        let height = min(maxSize.height, max(minSize.height, size.height))
        preferredContentSize = CGSize(width: width, height: height)
    }

    func deepPresentedViewController() -> UIViewController {
        var deepPresented: UIViewController = self
        while let presented = deepPresented.presentedViewController {
            deepPresented = presented
        }
        return deepPresented
    }

    /// Whether the presented view controller is still being presented or dismissed.
    ///
    /// On iOS 26 a dismissing popover morphs back into its source for about a second while the
    /// screen stays interactive. Presenting during that transition corrupts UIKit's state: the next
    /// presented sheet keeps `isBeingDismissed` stuck and ignores every dismiss. Check this before
    /// presenting and drop the presentation instead, as `presentPopover(_:pointingTo:)`,
    /// NoorUI's `BaseViewController` and `ModalPresentationCoordinator` do.
    var isPresentationTransitioning: Bool {
        guard let presentedViewController else {
            return false
        }
        return presentedViewController.isBeingPresented || presentedViewController.isBeingDismissed
    }

    /// Searches the receiver and its containment hierarchy breadth-first for a view controller of the requested type.
    func findViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        var queue = [self]
        while !queue.isEmpty {
            let viewController = queue.removeFirst()
            if let viewController = viewController as? T {
                return viewController
            }
            queue.append(contentsOf: viewController.children)
        }
        return nil
    }
}

private extension UIInterfaceOrientationMask {
    var preferredOrientation: UIInterfaceOrientation? {
        if contains(.portrait) {
            return .portrait
        } else if contains(.landscapeLeft) {
            return .landscapeLeft
        } else if contains(.landscapeRight) {
            return .landscapeRight
        } else if contains(.portraitUpsideDown) {
            return .portraitUpsideDown
        } else {
            return nil
        }
    }
}

public extension UIPageViewController {
    /// Returns the displayed view controller with the largest visible area.
    var mostVisibleViewController: UIViewController? {
        viewControllers?
            .compactMap { viewController -> (viewController: UIViewController, visibleArea: CGFloat)? in
                guard let displayedView = viewController.viewIfLoaded,
                      !displayedView.isHidden,
                      displayedView.alpha > 0
                else {
                    return nil
                }
                return (viewController, displayedView.visibleArea(in: view))
            }
            .max { lhs, rhs in lhs.visibleArea < rhs.visibleArea }?
            .viewController
    }
}
