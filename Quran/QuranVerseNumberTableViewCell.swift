//
//  QuranVerseNumberTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/21/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranVerseNumberTableViewCell: QuranTranslationBaseTableViewCell, TextReusableCell {

    @IBOutlet weak var roundedView: UIView!
    @IBOutlet weak var label: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        roundedView.layer.cornerRadius = roundedView.circularRadius
    }
}
