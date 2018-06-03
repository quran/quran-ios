//
//  ThemedLabel.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/5/18.
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

class ThemedLabel: UILabel {
    var usesTextColor = true {
        didSet { themeDidChange() }
    }

    open var kind: Theme.Kind = .label {
        didSet { themeDidChange() }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        themeDidChange()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func themeDidChange() {
        if usesTextColor {
            textColor = kind.color
        } else if let attributedText = self.attributedText {
            let mutableAttributedText = NSMutableAttributedString(attributedString: attributedText)
            mutableAttributedText.addAttribute(.foregroundColor,
                                               value: kind.color,
                                               range: NSRange(location: 0, length: attributedText.length))
            self.updatingAttributedText = true
            self.attributedText = mutableAttributedText
            self.updatingAttributedText = false
        }
    }

    private var updatingAttributedText = false

    override var attributedText: NSAttributedString? {
        didSet {
            if !updatingAttributedText {
                themeDidChange()
            }
        }
    }
}
