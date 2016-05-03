//
//  QuranPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class QuranPageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var highlightingView: HighlightingView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var pageLabel: UILabel!

    var page: QuranPage?
}
