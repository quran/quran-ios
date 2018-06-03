//
//  BaseNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
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

class BaseNavigationController: ThemedNavigationController, ScrollableToTop {

    override open var shouldAutorotate: Bool {
        return topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }
    override open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return topViewController?.preferredInterfaceOrientationForPresentation ?? super.preferredInterfaceOrientationForPresentation
    }
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationBar.barStyle = .black

        // show large titles if iOS 11
        if #available(iOS 11.0, *) {
            navigationBar.prefersLargeTitles = true
        }
    }

    func scrollToTop() {
        (topViewController as? ScrollableToTop)?.scrollToTop()
    }
}
