//
//  NavigationControllerDelegate.swift
//  Fresh List
//
//  Created by Mohamed Afifi on 1/5/19.
//  Copyright © 2019 Varaw. All rights reserved.
//

import UIKit

public protocol NavigationControllerPopMonitorDelegate: class {
    func viewControllerDidPop(_ controller: UIViewController)
}

public final class NavigationControllerPopMonitor: NSObject, UINavigationControllerDelegate {
    public weak var delegate: NavigationControllerPopMonitorDelegate?

    private var controllersCache: [UIViewController] = []

    public func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        // if the didShow called because of a pop happened
        if controllersCache.count > navigationController.viewControllers.count {
            for controller in controllersCache.reversed() {
                if !navigationController.viewControllers.contains(controller) {
                    delegate?.viewControllerDidPop(controller)
                }
            }
        }
        controllersCache = navigationController.viewControllers
    }
}
