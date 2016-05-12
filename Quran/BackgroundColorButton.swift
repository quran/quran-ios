//
//  BackgroundColorButton.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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

    @IBInspectable var normalBackground: UIColor = UIColor.lightGrayColor() {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var selectedBackground: UIColor = UIColor.blueColor() {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var highlightedBackground: UIColor = UIColor.redColor() {
        didSet {
            updateBackgroundColor()
        }
    }

    @IBInspectable var disabledBackground: UIColor = UIColor.darkGrayColor() {
        didSet {
            updateBackgroundColor()
        }
    }

    override var selected: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    override var enabled: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    override var highlighted: Bool {
        didSet {
            updateBackgroundColor()
        }
    }

    private func updateBackgroundColor() {

        let background: UIColor
        if !enabled {
            background = disabledBackground
        } else if highlighted {
            background = highlightedBackground
        } else if selected {
            background = selectedBackground
        } else {
            background = normalBackground
        }

        backgroundColor = background
    }
}
