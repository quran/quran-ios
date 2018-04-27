//
//  NoBorderSegmentedControl.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/26/18.
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
import UIKit

open class NoBorderSegmentedControl: UISegmentedControl {
    open func removeBorders() {
        setBackgroundImage((backgroundColor ?? .clear).image(), for: .normal, barMetrics: .default)
        setBackgroundImage((tintColor ?? .clear).image(), for: .selected, barMetrics: .default)
        setDividerImage(UIColor.clear.image(), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
    }

    open override func tintColorDidChange() {
        super.tintColorDidChange()
        removeBorders()
    }
}
