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

@MainActor
public protocol ForcedNavigationBarVisibilityController {
    var navigationBarHidden: Bool { get }
}

open class BaseNavigationController: UINavigationController {
    // MARK: Open

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    // MARK: Public

    override public var shouldAutorotate: Bool {
        topViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override public var prefersStatusBarHidden: Bool {
        topViewController?.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }

    override public func setNavigationBarHidden(_ hidden: Bool, animated: Bool) {
        if let vc = topViewController as? ForcedNavigationBarVisibilityController {
            super.setNavigationBarHidden(vc.navigationBarHidden, animated: animated)
        } else {
            super.setNavigationBarHidden(hidden, animated: animated)
        }
    }
}
