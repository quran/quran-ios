//
//  BaseViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/8/17.
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
import UIx
import VLogging

open class BaseViewController: UIViewController {
    // MARK: Open

    // Presenting mid-transition can leave UIKit stuck (see `isPresentationTransitioning`), so
    // drop the presentation instead. A dropped presentation never calls `completion`; it calls
    // `presentationWasDropped(_:)` instead.
    override open func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        guard !isPresentationTransitioning else {
            logger.warning("Dropped presenting \(type(of: viewControllerToPresent)) during a presentation transition")
            presentationWasDropped(viewControllerToPresent)
            return
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    /// Called when a presentation is dropped, so subclasses can undo state set up for it.
    open func presentationWasDropped(_ viewController: UIViewController) {
    }
}
