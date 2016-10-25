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
