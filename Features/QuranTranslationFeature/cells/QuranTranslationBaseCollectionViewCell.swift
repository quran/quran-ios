//
//  QuranTranslationBaseCollectionViewCell.swift
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
import QuranAnnotations
import QuranKit
import UIKit

class QuranTranslationBaseCollectionViewCell: UICollectionViewCell {
    // MARK: Lifecycle

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    // MARK: Internal

    var ayah: AyahNumber?

    var quranUITraits = QuranUITraits() {
        didSet {
            let versesByHighlights = quranUITraits.highlights.versesByHighlights()
            backgroundColor = ayah.flatMap { versesByHighlights[$0] }
        }
    }

    func setUp() {
    }

    func snapToReadableLeadingEdge(_ view: UIView) {
        let insets = ContentDimension.insets(of: self)
        snappedToReadableLeadingConstraints.append(view.vc.leading(by: insets.leading).constraint)
    }

    func snapToReadableTrailingEdge(_ view: UIView) {
        let insets = ContentDimension.insets(of: self)
        snappedToReadableLeadingConstraints.append(view.vc.trailing(by: insets.trailing).constraint)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateHorizontalConstraints()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateHorizontalConstraints()
    }

    // MARK: Private

    private var snappedToReadableLeadingConstraints: [NSLayoutConstraint] = []
    private var snappedToReadableTrailingConstraints: [NSLayoutConstraint] = []

    private func updateHorizontalConstraints() {
        let insets = ContentDimension.insets(of: self)
        for constraint in snappedToReadableLeadingConstraints {
            constraint.constant = insets.leading
        }
        for constraint in snappedToReadableTrailingConstraints {
            constraint.constant = insets.trailing
        }
    }
}

class QuranTranslationItemCollectionViewCell<Item>: QuranTranslationBaseCollectionViewCell {
    var item: Item?

    override var quranUITraits: QuranUITraits {
        didSet {
            if quranUITraits != oldValue {
                if let item {
                    configure(with: item)
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        item = nil
    }

    func configure(with item: Item) {
        self.item = item
    }
}
