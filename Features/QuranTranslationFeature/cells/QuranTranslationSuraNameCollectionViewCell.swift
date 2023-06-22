//
//  QuranTranslationSuraNameCollectionViewCell.swift
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

import NoorUI
import UIKit

class QuranTranslationSuraNameCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    // MARK: Internal

    let label = UILabel()

    override func setUp() {
        let contentView = UIView()

        let leftImage = decorationSideImage(themedImage(NoorImage.suraDecorationLeft.uiImage))
        let rightImage = decorationSideImage(themedImage(NoorImage.suraDecorationRight.uiImage))
        let middleImage = UIImageView(image: themedImage(NoorImage.suraDecorationMiddle.uiImage))

        contentView.addAutoLayoutSubview(leftImage)
        leftImage.vc.verticalEdges()
        leftImage.vc.leading()

        contentView.addAutoLayoutSubview(rightImage)
        rightImage.vc.verticalEdges()
        rightImage.vc.trailing()

        contentView.addAutoLayoutSubview(middleImage)
        middleImage.vc.verticalEdges()
        leftImage.vc.horizontalLine(middleImage, by: 1)
        middleImage.vc.horizontalLine(rightImage, by: 1)

        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20)
        label.adjustsFontSizeToFitWidth = true

        contentView.addAutoLayoutSubview(label)
        label.vc.leading(to: middleImage)
        label.vc.trailing(to: middleImage)
        label.vc.top(to: middleImage)
        label.vc.bottom(to: middleImage)

        self.contentView.addAutoLayoutSubview(contentView)
        contentView.vc
            .bottom()
            .height(by: Self.contentHeight)

        snapToReadableLeadingEdge(contentView)
        snapToReadableTrailingEdge(contentView)
        leftImageView = leftImage
        rightImageView = rightImage
        middleImageView = middleImage
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else {
            return
        }
        leftImageView?.image = themedImage(NoorImage.suraDecorationLeft.uiImage)
        rightImageView?.image = themedImage(NoorImage.suraDecorationRight.uiImage)
        middleImageView?.image = themedImage(NoorImage.suraDecorationMiddle.uiImage)
    }

    func configure(with text: String) {
        label.text = text
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size.height = Self.topPadding + Self.contentHeight
        return layoutAttributes
    }

    // MARK: Private

    private static var contentHeight: CGFloat = 50
    private static var topPadding: CGFloat = 10

    private var leftImageView: UIImageView?
    private var rightImageView: UIImageView?
    private var middleImageView: UIImageView?

    private func themedImage(_ image: UIImage) -> UIImage {
        if traitCollection.userInterfaceStyle == .dark {
            return image.inverted()
        }
        return image
    }

    private func decorationSideImage(_ image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: image.size.height / image.size.width).isActive = true
        return imageView
    }
}
