//
//  UIView+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/30/16.
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

extension UIView {
    public func findFirstResponder() -> UIView? {
        if isFirstResponder { return self }
        for subView in subviews {
            if let responder = subView.findFirstResponder() {
                return responder
            }
        }
        return nil
    }

    @discardableResult
    public func loadViewFrom(nibClass: UIView.Type) -> UIView {
        return loadViewFrom(nibName: String(describing: nibClass))
    }

    @discardableResult
    public func loadViewFrom(nibName: String) -> UIView {
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

    public func findSubview<T: UIView>(ofType type: T.Type) -> T? {
        // breadth-first search
        var queue = subviews
        while !queue.isEmpty {
            let subview = queue.removeFirst()
            if let subview = subview as? T {
                return subview
            }
            queue.append(contentsOf: subview.subviews)
        }
        return nil
    }

    public func findSubviews<T: UIView>(ofType type: T.Type) -> [T] {
        // breadth-first search
        var queue = subviews
        var result: [T] = []
        while !queue.isEmpty {
            let subview = queue.removeFirst()
            if let subview = subview as? T {
                result.append(subview)
            }
            queue.append(contentsOf: subview.subviews)
        }
        return result
    }
}

extension UIView {
    public var circularRadius: CGFloat {
        return min(bounds.width, bounds.height) / 2
    }
}
