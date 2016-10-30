//
//  UIView+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/30/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

extension UIView {
    func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subView in subviews {
            if let responder = subView.findFirstResponder() {
                return responder
            }
        }
        return nil
    }
}
