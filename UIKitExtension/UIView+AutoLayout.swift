//
//  UIView+AutoLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
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

    public func addAutoLayoutSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
    }

    @discardableResult
    public func addParentLeadingConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutConstraint.Attribute.leading,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.leading,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addParentTrailingConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.trailing,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: NSLayoutConstraint.Attribute.trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addParentTopConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addParentBottomConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: view,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addParentCenterXConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutConstraint.Attribute.centerX,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.centerX,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addParentCenterYConstraint(_ view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutConstraint.Attribute.centerY,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: self,
            attribute: NSLayoutConstraint.Attribute.centerY,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addHeightConstraint(_ value: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.height,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addWidthConstraint(_ value: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutConstraint.Attribute.width,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: nil,
            attribute: NSLayoutConstraint.Attribute.notAnAttribute,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func pinParentHorizontal(_ view: UIView, leadingValue: CGFloat = 0, trailingValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentLeadingConstraint(view, value: leadingValue))
        array.append(addParentTrailingConstraint(view, value: trailingValue))
        return array
    }

    @discardableResult
    public func pinParentVertical(_ view: UIView, topValue: CGFloat = 0, bottomValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentTopConstraint(view, value: topValue))
        array.append(addParentBottomConstraint(view, value: bottomValue))
        return array
    }

    @discardableResult
    public func pinParentAllDirections(_ view: UIView, leadingValue: CGFloat = 0, trailingValue: CGFloat = 0,
                                       topValue: CGFloat = 0, bottomValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array += pinParentHorizontal(view, leadingValue: leadingValue, trailingValue: trailingValue)
        array += pinParentVertical(view, topValue: topValue, bottomValue: bottomValue)
        return array
    }

    @discardableResult
    public func addParentCenter(_ view: UIView, centerX: CGFloat = 0, centerY: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentCenterXConstraint(view, value: centerX))
        array.append(addParentCenterYConstraint(view, value: centerY))
        return array
    }

    @discardableResult
    public func addSiblingHorizontalContiguous(left: UIView, right: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: right,
            attribute: NSLayoutConstraint.Attribute.leading,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: left,
            attribute: NSLayoutConstraint.Attribute.trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addSiblingVerticalContiguous(top: UIView, bottom: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: bottom,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: top,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func alignSiblingTop(first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutConstraint.Attribute.top,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: second,
            attribute: NSLayoutConstraint.Attribute.top,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func alignSiblingBottom(first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutConstraint.Attribute.bottom,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: second,
            attribute: NSLayoutConstraint.Attribute.bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func alignSiblingLeading(first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutConstraint.Attribute.leading,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: second,
            attribute: NSLayoutConstraint.Attribute.leading,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func alignSiblingTrailing(first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutConstraint.Attribute.trailing,
            relatedBy: NSLayoutConstraint.Relation.equal,
            toItem: second,
            attribute: NSLayoutConstraint.Attribute.trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    @discardableResult
    public func addEqualWidth(views: [UIView], value: CGFloat = 0) -> [NSLayoutConstraint] {

        assert(views.count > 1, "should have at least 2 views")

        let view1 = views[0]
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let view2 = views[i]
            let constraint = NSLayoutConstraint(
                item: view1,
                attribute: NSLayoutConstraint.Attribute.width,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: view2,
                attribute: NSLayoutConstraint.Attribute.width,
                multiplier: 1,
                constant: value)
            constraints.append(constraint)
            addConstraint(constraint)
        }

        return constraints
    }

    @discardableResult
    public func addEqualHeight(views: [UIView], value: CGFloat = 0) -> [NSLayoutConstraint] {

        assert(views.count > 1, "should have at least 2 views")

        let view1 = views[0]
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let view2 = views[i]
            let constraint = NSLayoutConstraint(
                item: view1,
                attribute: NSLayoutConstraint.Attribute.height,
                relatedBy: NSLayoutConstraint.Relation.equal,
                toItem: view2,
                attribute: NSLayoutConstraint.Attribute.height,
                multiplier: 1,
                constant: value)
            constraints.append(constraint)
            addConstraint(constraint)
        }

        return constraints
    }

    @discardableResult
    public func addEqualSize(views: [UIView], width: CGFloat = 0, height: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(contentsOf: addEqualHeight(views: views, value: height))
        array.append(contentsOf: addEqualWidth(views: views, value: width))
        return array
    }

    @discardableResult
    public func addSizeConstraints(width: CGFloat, height: CGFloat) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addWidthConstraint(width))
        array.append(addHeightConstraint(height))
        return array
    }
}
