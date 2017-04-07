//
//  QuranTranslationVerseSeparatorCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationVerseSeparatorCollectionViewCell: QuranTranslationBaseCollectionViewCell {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        let lineView = UIView()
        lineView.backgroundColor = #colorLiteral(red: 0.4862745098, green: 0.4862745098, blue: 0.4862745098, alpha: 1)

        contentView.addAutoLayoutSubview(lineView)
        contentView.pinParentHorizontal(lineView)
        contentView.addParentBottomConstraint(lineView)
        lineView.addHeightConstraint(1)
    }
}
