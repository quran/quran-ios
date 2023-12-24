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

class QuranTranslationArabicTextCollectionViewCell: QuranTranslationItemCollectionViewCell<(text: String, alignment: NSTextAlignment)> {
    // MARK: Internal

    let label = UILabel()

    override func setUp() {
        label.numberOfLines = 0
        label.textColor = .label

        contentView.addAutoLayoutSubview(label)
        label.vc.verticalEdges(top: Self.topPadding, bottom: Self.bottomPadding)
        snapToReadableLeadingEdge(label)
        snapToReadableTrailingEdge(label)
    }

    override func configure(with item: (text: String, alignment: NSTextAlignment)) {
        super.configure(with: item)
        label.attributedText = NSAttributedString(string: item.text, attributes: [
            .font: UIFont.arabicQuranText(ofSize: arabicFontSize),
        ])
        label.textAlignment = item.alignment
    }

    // MARK: Private

    private static let topPadding: CGFloat = 10
    private static let bottomPadding: CGFloat = 5
}
