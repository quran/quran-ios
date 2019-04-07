//
//  QariListPresenter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

final class QariListPresenter: PopoverPresenter {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .fullScreen
    }

    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return QariNavigationController(rootViewController: controller.presentedViewController)
    }
}

extension QariListPresenter {
    func present(
        presenting: UIViewController,
        presented: UIViewController,
        pointingTo sourceView: UIView) {
        presented.preferredContentSize = CGSize(width: 400, height: 500)
        super.present(presenting: presenting,
                      presented: presented,
                      pointingTo: sourceView,
                      at: sourceView.bounds,
                      permittedArrowDirections: .down)
    }
}
