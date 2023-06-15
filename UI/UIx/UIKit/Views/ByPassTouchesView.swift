//
//  ByPassTouchesView.swift
//  UIKitExtension
//
//  Created by Afifi, Mohamed on 3/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import UIKit

public class ByPassTouchesView: UIView {
    public var catchTouchesView: UIView?

    override public func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if catchTouchesView?.frame.contains(point) ?? false {
            return true
        }
        return false
    }
}
