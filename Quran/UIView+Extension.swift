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

    @discardableResult
    func loadViewFrom(nibClass: UIView.Type) -> UIView {
        return loadViewFrom(nibName: String(describing: nibClass))
    }

    @discardableResult
    func loadViewFrom(nibName: String) -> UIView {
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Couldn't load '\(nibName).xib' as the first item should be a UIView subclass.")
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                      options: [], metrics: nil, views: ["view": contentView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                      options: [], metrics: nil, views: ["view": contentView]))
        return contentView
    }
}

extension UIView {
    var circularRadius: CGFloat {
        return min(bounds.width, bounds.height) / 2
    }
}
