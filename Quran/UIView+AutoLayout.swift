//
//  UIView+AutoLayout.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

extension UIView {

    func addAutoLayoutSubview(subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
    }

    func addParentLeadingConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Leading,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.Leading,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addParentTrailingConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Trailing,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addParentTopConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.Top,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addParentBottomConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: view,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addParentCenterXConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.CenterX,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterX,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addParentCenterYConstraint(view: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: view,
            attribute: NSLayoutAttribute.CenterY,
            relatedBy: NSLayoutRelation.Equal,
            toItem: self,
            attribute: NSLayoutAttribute.CenterY,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addHeightConstraint(value: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Height,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addWidthConstraint(value: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: self,
            attribute: NSLayoutAttribute.Width,
            relatedBy: NSLayoutRelation.Equal,
            toItem: nil,
            attribute: NSLayoutAttribute.NotAnAttribute,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func pinParentHorizontal(view: UIView, leadingValue: CGFloat = 0, trailingValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentLeadingConstraint(view, value: leadingValue))
        array.append(addParentTrailingConstraint(view, value: trailingValue))
        return array
    }

    func pinParentVertical(view: UIView, topValue: CGFloat = 0, bottomValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentTopConstraint(view, value: topValue))
        array.append(addParentBottomConstraint(view, value: bottomValue))
        return array
    }

    func pinParentAllDirections(view: UIView, leadingValue: CGFloat = 0, trailingValue: CGFloat = 0,
                                topValue: CGFloat = 0, bottomValue: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array += pinParentHorizontal(view, leadingValue: leadingValue, trailingValue: trailingValue)
        array += pinParentVertical(view, topValue: topValue, bottomValue: bottomValue)
        return array
    }

    func addParentCenter(view: UIView, centerX: CGFloat = 0, centerY: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addParentCenterXConstraint(view, value: centerX))
        array.append(addParentCenterYConstraint(view, value: centerY))
        return array
    }

    func addSiblingHorizontalContiguous(left left: UIView, right: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: right,
            attribute: NSLayoutAttribute.Leading,
            relatedBy: NSLayoutRelation.Equal,
            toItem: left,
            attribute: NSLayoutAttribute.Trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addSiblingVerticalContiguous(top top: UIView, bottom: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: bottom,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: top,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func alignSiblingTop(first first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutAttribute.Top,
            relatedBy: NSLayoutRelation.Equal,
            toItem: second,
            attribute: NSLayoutAttribute.Top,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func alignSiblingBottom(first first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutAttribute.Bottom,
            relatedBy: NSLayoutRelation.Equal,
            toItem: second,
            attribute: NSLayoutAttribute.Bottom,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func alignSiblingLeading(first first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutAttribute.Leading,
            relatedBy: NSLayoutRelation.Equal,
            toItem: second,
            attribute: NSLayoutAttribute.Leading,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func alignSiblingTrailing(first first: UIView, second: UIView, value: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: first,
            attribute: NSLayoutAttribute.Trailing,
            relatedBy: NSLayoutRelation.Equal,
            toItem: second,
            attribute: NSLayoutAttribute.Trailing,
            multiplier: 1,
            constant: value)
        addConstraint(constraint)
        return constraint
    }

    func addEqualWidth(views views: [UIView], value: CGFloat = 0) -> [NSLayoutConstraint] {

        assert(views.count > 1, "should have at least 2 views")

        let view1 = views[0]
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let view2 = views[i]
            let constraint = NSLayoutConstraint(
                item: view1,
                attribute: NSLayoutAttribute.Width,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view2,
                attribute: NSLayoutAttribute.Width,
                multiplier: 1,
                constant: value)
            constraints.append(constraint)
            addConstraint(constraint)
        }

        return constraints
    }

    func addEqualHeight(views views: [UIView], value: CGFloat = 0) -> [NSLayoutConstraint] {

        assert(views.count > 1, "should have at least 2 views")

        let view1 = views[0]
        var constraints = [NSLayoutConstraint]()
        for i in 1..<views.count {
            let view2 = views[i]
            let constraint = NSLayoutConstraint(
                item: view1,
                attribute: NSLayoutAttribute.Height,
                relatedBy: NSLayoutRelation.Equal,
                toItem: view2,
                attribute: NSLayoutAttribute.Height,
                multiplier: 1,
                constant: value)
            constraints.append(constraint)
            addConstraint(constraint)
        }

        return constraints
    }

    func addEqualSize(views views: [UIView], width: CGFloat = 0, height: CGFloat = 0) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.appendContentsOf(addEqualHeight(views: views, value: height))
        array.appendContentsOf(addEqualWidth(views: views, value: width))
        return array
    }

    func addSizeConstraints(width width: CGFloat, height: CGFloat) -> [NSLayoutConstraint] {
        var array: [NSLayoutConstraint] = []
        array.append(addWidthConstraint(width))
        array.append(addHeightConstraint(height))
        return array
    }
}
