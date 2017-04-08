//
//  QariTableViewControllerCreator.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/19/17.
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
