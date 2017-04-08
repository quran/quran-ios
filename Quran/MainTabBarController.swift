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

import UIKit

class MainTabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.barStyle = .default
        delegate = self
    }

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if tabBarController.selectedViewController == viewController && viewController.isViewLoaded {
            if let navigationController = viewController as? UINavigationController {
                scrollToTop(navigationController.topViewController?.view)
            } else {
                scrollToTop(viewController.view)
            }
        }
        return true
    }

    private func scrollToTop(_ view: UIView?) {
        func _scrollToTop(_ view: UIView?) -> Bool {
            if let scrollView = view as? UIScrollView {
                scrollView.setContentOffset(.zero, animated: true)
                return true
            }
            return false
        }

        if !_scrollToTop(view) {
            for subview in view?.subviews ?? [] {
                if _scrollToTop(subview) {
                    break
                }
            }
        }
    }
}
