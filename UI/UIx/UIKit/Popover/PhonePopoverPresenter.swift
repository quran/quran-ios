//
//  PhonePopoverPresenter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import UIKit

public class PhonePopoverPresenter: PopoverPresenter {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}

public class PhoneAdapativeController: NSObject, UIAdaptivePresentationControllerDelegate, UISheetPresentationControllerDelegate {
    public static let shared = PhoneAdapativeController()

    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
}
