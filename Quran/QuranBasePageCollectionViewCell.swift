//
//  QuranBasePageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import PromiseKit

class QuranBasePageCollectionViewCell: UICollectionViewCell {

    var page: QuranPage?

    // MARK: - share specifics

    func ayahNumber(at point: CGPoint) -> AyahNumber? {
        expectedToBeSubclassed()
    }

    func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: VerseHighlightType) {
        expectedToBeSubclassed()
    }

    func highlightedVerse(forType type: VerseHighlightType) -> Set<AyahNumber>? {
        expectedToBeSubclassed()
    }
}
