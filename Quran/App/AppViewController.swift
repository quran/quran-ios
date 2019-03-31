//
//  MainTabBarController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import RIBs
import UIKit

protocol ScrollableToTop {
    func scrollToTop()
}

protocol AppPresentableListener: class {
}

class AppViewController: ThemedTabBarController, UITabBarControllerDelegate, AppPresentable, AppViewControllable {
    weak var listener: AppPresentableListener?

    override open var shouldAutorotate: Bool {
        return selectedViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return selectedViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return selectedViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController && viewController.isViewLoaded {
            (viewController as? ScrollableToTop)?.scrollToTop()
        }
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let targetMask = tabBarController.supportedInterfaceOrientations
        if let currentMask = UIApplication.shared.statusBarOrientation.asMask {
            if !targetMask.contains(currentMask) {
                if let interface = targetMask.asOrientation {
                    UIDevice.current.setValue(interface.rawValue, forKey: "orientation")
                }
            }
        }
    }

    func setViewControllers(_ viewControllers: [ViewControllable], animated: Bool) {
        setViewControllers(viewControllers.map { $0.uiviewController }, animated: animated)
    }
}

extension UIInterfaceOrientation {
    fileprivate var asMask: UIInterfaceOrientationMask? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

extension UIInterfaceOrientationMask {
    fileprivate var asOrientation: UIInterfaceOrientation? {
        if self.contains(.portrait) {
            return .portrait
        } else if self.contains(.landscapeLeft) {
            return .landscapeLeft
        } else if self.contains(.landscapeRight) {
            return .landscapeRight
        } else if self.contains(.portraitUpsideDown) {
            return .portraitUpsideDown
        } else {
            return nil
        }
    }
}
