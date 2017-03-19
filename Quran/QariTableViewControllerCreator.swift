//
//  QariTableViewControllerCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QariTableViewControllerCreator: NSObject, Creator, UIPopoverPresentationControllerDelegate {

    private let qarisControllerCreator: AnyCreator<QariTableViewController, ([Qari], Int)>
    init(qarisControllerCreator: AnyCreator<QariTableViewController, ([Qari], Int)>) {
        self.qarisControllerCreator = qarisControllerCreator
    }

    func create(_ parameters: ([Qari], Int, UIView?)) -> QariTableViewController {
        let controller = qarisControllerCreator.create(parameters.0, parameters.1)

        controller.preferredContentSize = CGSize(width: 400, height: 500)
        controller.modalPresentationStyle = .popover
        controller.popoverPresentationController?.delegate = self
        controller.popoverPresentationController?.sourceView = parameters.2
        controller.popoverPresentationController?.sourceRect = parameters.2?.bounds ?? CGRect.zero
        controller.popoverPresentationController?.permittedArrowDirections = .down
        return controller
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .fullScreen
    }

    func presentationController(_ controller: UIPresentationController,
                                viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        return QariNavigationController(rootViewController: controller.presentedViewController)
    }
}
