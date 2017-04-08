//
//  BackgroundColorButton.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
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

class BackgroundColorButton: UIButton {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    func setUp() {
        updateBackgroundColor()
    }

    @IBInspectable var normalBackground: UIColor = UIColor.lightGray {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var selectedBackground: UIColor = UIColor.blue {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var highlightedBackground: UIColor = UIColor.red {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var disabledBackground: UIColor = UIColor.darkGray {
        didSet {
            updateBackgroundColor()
        }
    }

    override var isSelected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    override var isEnabled: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    fileprivate func updateBackgroundColor() {

        let background: UIColor
        if !isEnabled {
            background = disabledBackground
        } else if isHighlighted {
            background = highlightedBackground
        } else if isSelected {
            background = selectedBackground
        } else {
            background = normalBackground
        }

        backgroundColor = background
    }
}
