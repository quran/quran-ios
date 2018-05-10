//
//  QuranTranslationArabicTextCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
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

class QuranTranslationArabicTextCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    static let topPadding: CGFloat = 15
    static let bottomPadding: CGFloat = 15

    let label: UILabel = UILabel()
    private var labelLeading: NSLayoutConstraint?
    private var labelTrailing: NSLayoutConstraint?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        label.numberOfLines = 0
        label.textAlignment = .right
        label.textColor = .translationText
        label.backgroundColor = .readingBackground()

        contentView.addAutoLayoutSubview(label)
        label.vc.verticalEdges(top: type(of: self).topPadding, bottom: type(of: self).bottomPadding)
        labelLeading = label.vc.leading(by: leadingMargin).constraint
        labelTrailing = label.vc.trailing(by: trailingMargin).constraint
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        labelLeading?.constant = leadingMargin
        labelTrailing?.constant = trailingMargin
    }

    override var backgroundColor: UIColor? {
        didSet {
            if backgroundColor == .readingBackground() {
                label.backgroundColor = backgroundColor
            } else {
                label.backgroundColor = .clear
            }
        }
    }
}
