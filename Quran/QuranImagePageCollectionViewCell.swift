//
//  QuranImagePageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
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
import PromiseKit

private let imageHeightDiff: CGFloat = 34
private let imageWidthDiff : CGFloat = 10

class QuranImagePageCollectionViewCell: QuranBasePageCollectionViewCell {

    @IBOutlet weak var juzLabel: UILabel!
    @IBOutlet weak var suraLabel: UILabel!
    @IBOutlet weak var pageLabel: UILabel!

    @IBOutlet weak var highlightingView: QuranImageHighlightingView!
    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!

    private var sizeConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.backgroundColor = UIColor.readingBackground()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.contentOffset = .zero
        highlightingView.reset()
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        sizeConstraints.forEach { mainImageView.removeConstraint($0) }
        sizeConstraints.removeAll()

        let imageViewSize: CGSize
        if let imageSize = mainImageView.image?.size, bounds.width > bounds.height {
            // add fill height
            imageViewSize = CGSize(width: bounds.width - imageWidthDiff,
                                   height: bounds.width * (imageSize.height / imageSize.width))
        } else {
            // add fit height
            imageViewSize = CGSize(width:  bounds.width  - imageWidthDiff,
                                   height: bounds.height - imageHeightDiff)
        }
        sizeConstraints.append(mainImageView.addHeightConstraint(imageViewSize.height))
        if let imageSize = mainImageView.image?.size {
            let scale: CGFloat
            if imageSize.width / imageSize.height < imageViewSize.width / imageViewSize.height {
                scale = imageViewSize.height / imageSize.height
            } else {
                scale = imageViewSize.width / imageSize.width
            }
            let xOffset = (imageViewSize.width - (scale * imageSize.width)) / 2
            let yOffset = (imageViewSize.height - (scale * imageSize.height)) / 2
            highlightingView.imageScale = CGRect.Scale(scale: scale, xOffset: xOffset, yOffset: yOffset)
            scrollToReadingHighlightedAyat()
        }
    }

    func setAyahInfo(_ ayahInfoData: [AyahNumber: [AyahInfo]]?) {
        highlightingView.ayahInfoData = ayahInfoData
        scrollToReadingHighlightedAyat()
    }

    private func scrollToReadingHighlightedAyat() {
        guard let rectangles = highlightingView.highlightingRectangles[.reading], !rectangles.isEmpty else {
            return
        }

        layoutIfNeeded()

        var union = rectangles[0]
        rectangles.forEach { union = union.union($0) }

        let contentOffset = max(0, min(union.minY - 60, scrollView.contentSize.height - scrollView.bounds.height))
        scrollView.setContentOffset(CGPoint(x: 0, y: contentOffset), animated: true)
    }

    // MARK: - share specifics

    override func ayahNumber(at point: CGPoint) -> AyahNumber? {
        let localPoint = highlightingView.convert(point, from: self)
        return highlightingView.ayahNumber(at: localPoint)
    }

    override func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: VerseHighlightType) {
        highlightingView.highlights[type] = verses
        if type == .reading {
            scrollToReadingHighlightedAyat()
        }
    }

    override func highlightedVerse(forType type: VerseHighlightType) -> Set<AyahNumber>? {
        return highlightingView.highlights[type]
    }
}
