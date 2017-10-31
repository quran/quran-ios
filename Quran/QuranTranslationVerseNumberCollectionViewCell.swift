//
//  QuranTranslationVerseNumberCollectionViewCell.swift
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

class QuranTranslationVerseNumberCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    static let cellHeight: CGFloat = 80

    let roundedView: UIView = CircularView()
    let label: UILabel = UILabel()
    private var roundedViewLeading: NSLayoutConstraint?

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
        roundedView.vc.verticalEdges(inset: 10)
        roundedViewLeading = roundedView.vc.leading(by: leadingMargin).constraint
        roundedView.heightAnchor.constraint(equalTo: roundedView.widthAnchor).isActive = true

        roundedView.addAutoLayoutSubview(label)
        label.vc.edges(inset: 10)
    }

    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        roundedViewLeading?.constant = leadingMargin
    }
}
