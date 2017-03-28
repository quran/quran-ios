//
//  QuranTranslationBaseTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 3/25/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class QuranTranslationBaseTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .readingBackground()
        contentView.backgroundColor = .readingBackground()
    }
}
