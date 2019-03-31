//
//  UIViewController+Extensions.swift
//  Bday
//
//  Created by Mohamed Afifi on 1/15/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import UIKit

extension UIViewController {

    func addFullScreenChild(_ viewController: UIViewController) {
        addChild(viewController)

        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(viewController.view)
        viewController.view.vc.edges()
        viewController.didMove(toParent: self)
    }

    func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
