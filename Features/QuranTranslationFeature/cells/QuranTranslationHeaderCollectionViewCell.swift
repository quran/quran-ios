//
//  QuranTranslationHeaderCollectionViewCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 1/13/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Localization
import NoorUI
import QuranKit
import UIKit

struct TranslationPageHeader {
    let verse: AyahNumber
}

class QuranTranslationHeaderCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    // MARK: Internal

    override func setUp() {
        let contentView = UIView()
        leftLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        leftLabel.setContentCompressionResistancePriority(.defaultHigh + 2, for: .horizontal)
        rightLabel.textAlignment = .natural

        for label in [leftLabel, rightLabel] {
            label.textColor = .label
            label.font = Self.font
            contentView.addAutoLayoutSubview(label)
            label.vc.verticalEdges()
        }
        leftLabel.vc.leading()
        rightLabel.vc.trailing()
        leftLabel.trailingAnchor.constraint(lessThanOrEqualTo: rightLabel.leadingAnchor, constant: -40).isActive = true

        self.contentView.addAutoLayoutSubview(contentView)
        contentView.vc.bottom(by: Self.bottomPadding)
        snapToReadableLeadingEdge(contentView)
        snapToReadableTrailingEdge(contentView)
    }

    func configure(with header: TranslationPageHeader) {
        leftLabel.text = header.verse.page.localizedQuarterName
        rightLabel.attributedText = header.verse.page.suraNames()
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        layoutIfNeeded()
        let insets = ContentDimension.insets(of: self)
        layoutAttributes.size.height = insets.top + max(leftLabel.bounds.height, rightLabel.bounds.height) + Self.topPadding + Self.bottomPadding
        return layoutAttributes
    }

    // MARK: Private

    private static let topPadding: CGFloat = 0
    private static let bottomPadding: CGFloat = ContentDimension.interSpacing

    private static var font: UIFont {
        .systemFont(ofSize: 14)
    }

    private let leftLabel = UILabel()
    private let rightLabel = UILabel()
}
