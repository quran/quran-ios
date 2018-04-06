//
//  Button.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-05.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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
open class Button: UIButton {

    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if isHidden || !isUserInteractionEnabled || alpha < 0.01 { return nil }

        let minimumHitArea = CGSize(width: 44, height: 44)// if the button is hidden/disabled/transparent it can't be hit
        // increase the hit frame to be at least as big as `minimumHitArea`
        let widthToAdd = max(minimumHitArea.width - bounds.width, 0)
        let heightToAdd = max(minimumHitArea.height - bounds.height, 0)
        let largerFrame = self.bounds.insetBy(dx: -widthToAdd / 2, dy: -heightToAdd / 2)

        // perform hit test on larger frame
        return (largerFrame.contains(point)) ? self : nil
    }
}
