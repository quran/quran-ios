//
//  QuranPageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import AVFoundation

private let imageHeightDiff: CGFloat = 34

class QuranPageCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var juzLabel: UILabel!
    @IBOutlet weak var suraLabel: UILabel!
    @IBOutlet weak var pageLabel: UILabel!

    @IBOutlet weak var highlightingView: HighlightingView!
    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!

    var page: QuranPage?
    var sizeConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.backgroundColor = UIColor.readingBackground()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.contentOffset = CGPoint.zero
        highlightingView.reset()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sizeConstraints.forEach { mainImageView.removeConstraint($0) }
        sizeConstraints.removeAll()

        if let imageSize = mainImageView.image?.size where bounds.width > bounds.height {
            // add fill height
            let height = bounds.width * (imageSize.height / imageSize.width)
            sizeConstraints.append(mainImageView.addHeightConstraint(height))
        } else {
            // add fit height
            sizeConstraints.append(mainImageView.addHeightConstraint(bounds.height - imageHeightDiff))
        }
        mainImageView.layoutIfNeeded()

        if let imageSize = mainImageView.image?.size {
            let scale: CGFloat
            if imageSize.width / imageSize.height < mainImageView.frame.size.width / mainImageView.frame.size.height {
                scale = mainImageView.frame.size.height / imageSize.height
            } else {
                scale = mainImageView.frame.size.width / imageSize.width
            }
            let deltaX = (mainImageView.frame.size.width - (scale * imageSize.width)) / 2
            let deltaY = (mainImageView.frame.size.height - (scale * imageSize.height)) / 2
            highlightingView.setScaleInfo(scale, xOffset: deltaX, yOffset: deltaY)
        }
    }

    func setAyahInfo(ayahInfoData: [AyahNumber: [AyahInfo]]?) {
        highlightingView.ayahInfoData = ayahInfoData
    }

    func highlightAyah(ayat: Set<AyahNumber>) {
        highlightingView.highlightedAyat = ayat
    }
}
