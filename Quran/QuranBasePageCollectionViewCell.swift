//
//  QuranBasePageCollectionViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
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

class QuranBasePageCollectionViewCell: BackgroundThemedCollectionViewCell, AyahMenuCell {

    var onScrollViewWillBeginDragging: (() -> Void)? {
        get { return scrollNotifier.onScrollViewWillBeginDragging }
        set { return scrollNotifier.onScrollViewWillBeginDragging = newValue }
    }

    let scrollNotifier = ScrollViewDelegateNotifier()

    var page: QuranPage?

    // MARK: - share specifics

    func ayahWordPosition(at point: CGPoint) -> AyahWord.Position? {
        expectedToBeSubclassed()
    }

    func setHighlightedVerses(_ verses: Set<AyahNumber>?, forType type: QuranHighlightType) {
        expectedToBeSubclassed()
    }

    func highlightedVerse(forType type: QuranHighlightType) -> Set<AyahNumber>? {
        expectedToBeSubclassed()
    }

    func highlight(position: AyahWord.Position?) {
        expectedToBeSubclassed()
    }
}
