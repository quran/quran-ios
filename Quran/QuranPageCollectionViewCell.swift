//
//  QuranPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import AVFoundation

class QuranPageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var highlightingView: HighlightingView!
    @IBOutlet weak var mainImageView: UIImageView!
    @IBOutlet weak var pageLabel: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!

    var page: QuranPage?

    var sizeConstraints: [NSLayoutConstraint] = []

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.contentOffset = CGPoint.zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let imageSize = mainImageView.image?.size else {
            return
        }

        sizeConstraints.forEach { mainImageView.removeConstraint($0) }
        sizeConstraints.removeAll()

        if bounds.width > bounds.height {
            // add fill height
            let height = bounds.width * (imageSize.height / imageSize.width)
            sizeConstraints.append(mainImageView.addHeightConstraint(height))
        } else {
            // add fit height
            sizeConstraints.append(mainImageView.addHeightConstraint(bounds.height - 10))
        }
    }
}
