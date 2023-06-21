//
//  QuranTranslationFooterCollectionViewCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/13/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import NoorUI
import QuranKit
import UIKit

class QuranTranslationFooterCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    // MARK: Internal

    override func setUp() {
        label.textColor = .label
        label.textAlignment = .center
        label.font = Self.font

        contentView.addAutoLayoutSubview(label)
        label.vc.top(by: Self.topPadding)
        snapToReadableLeadingEdge(label)
        snapToReadableTrailingEdge(label)
    }

    func configure(with page: Page) {
        label.text = page.localizedNumber
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutIfNeeded()
        let insets = ContentDimension.insets(of: self)
        layoutAttributes.size.height = insets.bottom + label.bounds.height + Self.topPadding + Self.bottomPadding
        return layoutAttributes
    }

    // MARK: Private

    private static let topPadding: CGFloat = ContentDimension.interSpacing
    private static let bottomPadding: CGFloat = 0

    private static var font: UIFont {
        .systemFont(ofSize: 14)
    }

    private let label = UILabel()
}
