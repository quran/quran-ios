//
//  QuranTranslationVerseSeparatorCollectionViewCell.swift
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

class QuranTranslationVerseSeparatorCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    // MARK: Internal

    let fillColor = UIView()
    let shadowImage = UIImageView(image: NoorImage.innerShadow.uiImage)

    override var backgroundColor: UIColor? {
        didSet {
            super.backgroundColor = nil
        }
    }

    override func setUp() {
        // shadow image
        contentView.addAutoLayoutSubview(shadowImage)
        shadowImage.vc.edges()

        fillColor.backgroundColor = .systemGray5
        contentView.addAutoLayoutSubview(fillColor)
        fillColor.vc.edges()

        updateVisibleUI()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateVisibleUI()
    }

    func configure(with item: Void) {}

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutAttributes.size.height = Self.cellHeight
        return layoutAttributes
    }

    // MARK: Private

    private static let lineHeight: CGFloat = 1
    private static let cellHeight: CGFloat = 10

    private func updateVisibleUI() {
        fillColor.isHidden = traitCollection.userInterfaceStyle == .light
        shadowImage.isHidden = !fillColor.isHidden
    }
}
