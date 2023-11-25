//
//  PopoverPresenter.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/19/17.
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
public protocol PopoverPresenterDelegate: AnyObject {
    func didDismissPopover()
}

public class PopoverPresenter: NSObject, UIPopoverPresentationControllerDelegate {
    // MARK: Lifecycle

    public init(delegate: PopoverPresenterDelegate?) {
        self.delegate = delegate
    }

    // MARK: Public

    public func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
        delegate?.didDismissPopover()
    }

    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        delegate?.didDismissPopover()
    }

    // MARK: Internal

    weak var delegate: PopoverPresenterDelegate?
}

extension PopoverPresenter {
    public func present(
        presenting: UIViewController,
        presented: UIViewController,
        pointingTo sourceView: UIView,
        at sourceRect: CGRect,
        permittedArrowDirections: UIPopoverArrowDirection = .any,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        presented.modalPresentationStyle = .popover
        presented.popoverPresentationController?.delegate = self
        presented.popoverPresentationController?.sourceView = sourceView
        presented.popoverPresentationController?.sourceRect = sourceRect
        presented.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        presenting.present(presented, animated: animated, completion: completion)
    }
}

extension UIViewController {
    public func presentPopover(
        _ presented: UIViewController,
        pointingTo barButtonItem: UIBarButtonItem,
        permittedArrowDirections: UIPopoverArrowDirection = .any,
        animated: Bool = true,
        completion: (() -> Void)? = nil
    ) {
        presented.modalPresentationStyle = .popover
        presented.presentationController?.delegate = PhonePopoverAdapativeController.shared
        presented.popoverPresentationController?.barButtonItem = barButtonItem
        presented.popoverPresentationController?.permittedArrowDirections = permittedArrowDirections
        present(presented, animated: animated, completion: completion)
    }
}
