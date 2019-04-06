//
//  QariListPresenter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import Foundation

final class QariListPresenter: NSObject, UIPopoverPresentationControllerDelegate {

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
        presented.modalPresentationStyle = .popover
        presented.popoverPresentationController?.delegate = self
        presented.popoverPresentationController?.sourceView = sourceView
        presented.popoverPresentationController?.sourceRect = sourceView.bounds
        presented.popoverPresentationController?.permittedArrowDirections = .down
        presenting.present(presented, animated: true, completion: nil)
    }
}
