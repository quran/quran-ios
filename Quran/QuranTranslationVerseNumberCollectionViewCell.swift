//
//  QuranTranslationVerseNumberCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/31/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationVerseNumberCollectionViewCell: QuranTranslationBaseCollectionViewCell {

    let roundedView: UIView = CircularView()
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
        roundedView.backgroundColor = #colorLiteral(red: 0.8861932158, green: 0.8862140179, blue: 0.8862028718, alpha: 1)

        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 0.4862189293, green: 0.4863064885, blue: 0.4862134457, alpha: 1)
        label.font = UIFont.systemFont(ofSize: 17)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5

        contentView.addAutoLayoutSubview(roundedView)
        contentView.pinParentVertical(roundedView, topValue: 10, bottomValue: 10)
        contentView.addParentLeadingConstraint(roundedView, value: 12)
        roundedView.heightAnchor.constraint(equalTo: roundedView.widthAnchor).isActive = true

        roundedView.addAutoLayoutSubview(label)
        roundedView.pinParentAllDirections(label, leadingValue: 10, trailingValue: 10, topValue: 10, bottomValue: 10)
    }
}
