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

    func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
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
}
