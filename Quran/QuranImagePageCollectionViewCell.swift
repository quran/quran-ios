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
import PromiseKit
import UIKit

class QuranImagePageCollectionViewCell: QuranBasePageCollectionViewCell {

    @IBOutlet weak var scrollViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageTrailingConstraint: NSLayoutConstraint!

    @IBOutlet weak var juzLabel: ThemedLabel!
    @IBOutlet weak var suraLabel: ThemedLabel!
    @IBOutlet weak var pageLabel: ThemedLabel!

    @IBOutlet weak var highlightingView: QuranImageHighlightingView!
    @IBOutlet weak var mainImageView: UIImageView!

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var backgroundThemedView: ThemedView!

    private var sizeConstraints: [NSLayoutConstraint] = []

    override func awakeFromNib() {
        backgroundThemedView.kind = .backgroundOLED
        juzLabel.kind = .labelStrong
        suraLabel.kind = .labelStrong
        pageLabel.kind = .labelStrong
        super.awakeFromNib()
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        scrollViewLeadingConstraint.constant = Layout.QuranCell.horizontalInset
        scrollViewTrailingConstraint.constant = Layout.QuranCell.horizontalInset
        scrollView.delegate = scrollNotifier
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.contentOffset = .zero
        highlightingView.reset()
    }

    private func updateImageConstraints() {
        let verticalMargin: CGFloat = 10
        // we are using window's layoutMargins to prevent the margin to change while scrolling
        let directionalLayoutMargins = Layout.windowDirectionalLayoutMargins
        imageLeadingConstraint.constant = directionalLayoutMargins.leading
        imageTrailingConstraint.constant = directionalLayoutMargins.trailing
        imageTopConstraint.constant = directionalLayoutMargins.top + verticalMargin
        imageBottomConstraint.constant = directionalLayoutMargins.bottom + verticalMargin

        // update scrollbar insets
        scrollView.scrollIndicatorInsets = UIEdgeInsets(top: layoutMargins.top,
                                                        left: Layout.windowDirectionalSafeAreaInsets.leading,
                                                        bottom: layoutMargins.bottom,
                                                        right: Layout.windowDirectionalSafeAreaInsets.trailing)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateImageConstraints()

        let widthInset = imageLeadingConstraint.constant +
                         imageTrailingConstraint.constant +
                         scrollViewLeadingConstraint.constant +
                         scrollViewTrailingConstraint.constant
        let heightInset = imageTopConstraint.constant + imageBottomConstraint.constant

        sizeConstraints.forEach { mainImageView.removeConstraint($0) }
        sizeConstraints.removeAll()

        let imageVisibleSize = CGSize(width: bounds.width - widthInset, height: bounds.height - heightInset)

        let imageViewSize: CGSize
        if let imageSize = mainImageView.image?.size, imageVisibleSize.width > imageVisibleSize.height {
            // add fill height
            imageViewSize = CGSize(width: imageVisibleSize.width, height: imageVisibleSize.width * (imageSize.height / imageSize.width))
        } else {
            // add fit height
            imageViewSize = imageVisibleSize
        }
        sizeConstraints.append(mainImageView.vc.height(by: imageViewSize.height).constraint)
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

        var rectangles: [CGRect] = []
        for highlightType in QuranHighlightType.scrollingTypes {
            if let rects = highlightingView.highlightingRectangles[highlightType], !rects.isEmpty {
                rectangles = rects
                break
            }
        }
        guard !rectangles.isEmpty else {
            return
        }

        layoutIfNeeded()

        var union = rectangles[0]
        rectangles.forEach { union = union.union($0) }

        let contentOffset = max(0, min(union.minY - 60, scrollView.contentSize.height - scrollView.bounds.height))
        scrollView.setContentOffset(CGPoint(x: 0, y: contentOffset), animated: true)
    }

    // MARK: - share specifics

    override func ayahWordPosition(at point: CGPoint) -> AyahWord.Position? {
        let localPoint = highlightingView.convert(point, from: self)
        return highlightingView.ayahWordPosition(at: localPoint, view: self)
    }

    override func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: QuranHighlightType) {
        highlightingView.highlights[type] = verses
        if QuranHighlightType.scrollingTypes.contains(type) {
            scrollToReadingHighlightedAyat()
        }
    }

    override func highlightedVerse(forType type: QuranHighlightType) -> Set<AyahNumber>? {
        return highlightingView.highlights[type]
    }

    override func highlight(position: AyahWord.Position?) {
        highlightingView.highlightedPosition = position
    }
}
