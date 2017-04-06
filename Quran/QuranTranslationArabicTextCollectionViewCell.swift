//
//  QuranTranslationArabicTextCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationArabicTextCollectionViewCell: QuranTranslationBaseCollectionViewCell {

    let label: UILabel = UILabel()

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
        label.font = .translationArabicQuranText
        label.textColor = .translationText
        label.backgroundColor = .readingBackground()

        contentView.addAutoLayoutSubview(label)
        contentView.pinParentAllDirections(label,
                                           leadingValue: Layout.Translation.horizontalInset,
                                           trailingValue: Layout.Translation.horizontalInset,
                                           topValue: 15,
                                           bottomValue: 15)
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
