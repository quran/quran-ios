//
//  QuranTranslationBaseCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationBaseCollectionViewCell: UICollectionViewCell {

    var ayah: AyahNumber?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        backgroundColor = .readingBackground()
        contentView.backgroundColor = .readingBackground()
    }

    override var backgroundColor: UIColor? {
        set {
            super.backgroundColor = newValue ?? .readingBackground()
            contentView.backgroundColor = super.backgroundColor
        }
        get {
            return super.backgroundColor
        }
    }
}
