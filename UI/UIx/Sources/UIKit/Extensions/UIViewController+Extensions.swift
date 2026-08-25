//
//  UIViewController+Extensions.swift
//  Bday
//
//  Created by Mohamed Afifi on 1/15/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import UIKit

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

    func rotateToPortraitIfPhone() {
        if traitCollection.userInterfaceIdiom == .phone {
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
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
