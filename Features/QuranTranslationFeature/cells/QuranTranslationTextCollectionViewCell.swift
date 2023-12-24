//
//  QuranTranslationTextCollectionViewCell.swift
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

import Localization
import NoorUI
import QuranKit
import QuranText
import UIKit
import UIx

struct TranslationTextData {
    let collapsedNumberOfLines: UInt
    let verse: AyahNumber
    let translation: Translation
    let text: TranslationString
    var isExpanded: Bool
    let showTranslator: Bool
    let translationTapped: (Translation) -> Void
}

class QuranTranslationTextCollectionViewCell: QuranTranslationItemCollectionViewCell<TranslationTextData> {
    // MARK: Public

    public static let maxNumberOfLines = 10

    // MARK: Internal

    override var backgroundColor: UIColor? {
        didSet {
            shadow.fillColor = backgroundColor ?? UIColor.reading
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        translationLabel.prepareForReuse()
    }

    override func setUp() {
        textStack.axis = .vertical
        textStack.distribution = .fill
        textStack.alignment = .fill
        textStack.spacing = Self.textSpacing

        // shadow
        shadow.cornerRadius = 10.0
        shadow.shadowOpacity = 0.2
        shadow.shadowRadius = 3
        shadow.shadowOffset = .zero
        contentView.addAutoLayoutSubview(shadow)
        shadow.vc.verticalEdges(top: Self.shadowTopPadding, bottom: Self.shadowBottomPadding)
        snapToReadableLeadingEdge(shadow)
        snapToReadableTrailingEdge(shadow)

        // stack
        shadow.addAutoLayoutSubview(textStack)
        textStack.vc.edges(
            leading: Self.textHorizontalPadding,
            trailing: Self.textHorizontalPadding,
            top: Self.textTopPadding,
            bottom: Self.textBottomPadding
        )

        // translator
        translatorLabel.textColor = .secondaryLabel
        textStack.addArrangedSubview(translatorLabel)

        // translation
        textStack.addArrangedSubview(translationLabel.view)

        setUpReadMoreTapped()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            if let item {
                configure(with: item)
            }
        }
    }

    override func configure(with item: TranslationTextData) {
        super.configure(with: item)
        shadow.shadowColor = UIColor.label

        translatorLabel.isHidden = !item.showTranslator
        translatorLabel.font = item.translation.preferredTranslatorNameFont(ofSize: translationFontSize)
        translatorLabel.text = item.translation.translationName

        translationLabel.collapsedNumberOfLines = item.collapsedNumberOfLines
        translationLabel.showAsExpanded(item.isExpanded)
        translationLabel.attributedText = attributedText(
            verse: item.verse,
            translation: item.translation,
            text: item.text
        )
        translationLabel.truncationAttributedText = truncationAttributedText(translation: item.translation)
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let insets = ContentDimension.insets(of: self)
        let width = layoutAttributes.size.width - insets.leading - insets.trailing - Self.textHorizontalPadding * 2
        let translationLabelHeight = translationLabel.heightThatFits(width: width)
        layoutAttributes.size.height = Self.shadowTopPadding
            + Self.textTopPadding
            + ceil(translationLabelHeight)
            + Self.textBottomPadding
            + Self.shadowBottomPadding

        if !translatorLabel.isHidden {
            let translatorSize = (translatorLabel.text ?? "").size(withFont: translatorLabel.font)
            layoutAttributes.size.height += ceil(translatorSize.height) + Self.textSpacing
        }
        return layoutAttributes
    }

    // MARK: Private

    private static let shadowTopPadding: CGFloat = 15
    private static let shadowBottomPadding: CGFloat = 15

    private static let textTopPadding: CGFloat = 10
    private static let textBottomPadding: CGFloat = 10
    private static let textHorizontalPadding: CGFloat = 10
    private static let textSpacing: CGFloat = 5

    private let textStack = UIStackView()
    private let translatorLabel = UILabel()
    private let translationLabel = ExpandableLabel()

    private let shadow = RoundedShadowView()

    private func setUpReadMoreTapped() {
        translationLabel.onExpandCollapseButtonTapped = { [weak self] in
            if let item = self?.item {
                item.translationTapped(item.translation)
            }
        }
    }

    private func truncationAttributedText(translation: Translation) -> NSAttributedString {
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle(translation: translation),
            .font: truncationLabelFont(translation: translation),
            .foregroundColor: UIColor.secondaryLabel.resolvedColor(with: traitCollection),
        ]
        let ellipsis = NSAttributedString(string: "\u{2026}", attributes: attributes)
        let readMore = NSAttributedString(string: l("translation.text.read-more"), attributes: attributes)

        let text = NSMutableAttributedString(attributedString: ellipsis)
        text.mutableString.append(" ")
        text.append(readMore)
        return text
    }

    private func paragraphStyle(translation: Translation) -> NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        if translation.characterDirection == .rightToLeft {
            style.alignment = .right
        } else {
            style.alignment = .left
        }
        return style
    }

    private func truncationLabelFont(translation: Translation) -> UIFont {
        textFont(translation: translation)
    }

    private func textFont(translation: Translation) -> UIFont {
        translation.preferredTextFont(ofSize: translationFontSize)
    }

    private func footerFont(translation: Translation) -> UIFont {
        translation.preferredTextFont(ofSize: translationFontSize, factor: 0.7)
    }

    private func attributedText(
        verse: AyahNumber,
        translation: Translation,
        text: TranslationString
    ) -> NSAttributedString {
        let color = UIColor.label.resolvedColor(with: traitCollection)
        let footerColor = UIColor.secondaryLabel.resolvedColor(with: traitCollection)
        let quranColor = UIColor.appIdentity.resolvedColor(with: traitCollection)
        let font = textFont(translation: translation)
        let footerFont = footerFont(translation: translation)

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle(translation: translation),
            .font: font,
            .foregroundColor: color,
        ]
        let attributedString = NSMutableAttributedString(string: text.text, attributes: attributes)

        for range in text.footerRanges {
            attributedString.addAttributes([
                .font: footerFont,
                .foregroundColor: footerColor,
            ], range: range)
        }

        for range in text.quranRanges {
            attributedString.addAttributes([
                .foregroundColor: quranColor,
            ], range: range)
        }

        // add verse number
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: translation.languageCode)
        let translationVerseNumber = formatter.format(verse.ayah)
        attributedString.insert(NSAttributedString(string: translationVerseNumber + ". ", attributes: attributes), at: 0)

        return attributedString
    }
}
