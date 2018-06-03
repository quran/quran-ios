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

import UIKit

class QuranTranslationVerseSeparatorCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    private static let lineHeight: CGFloat = 1
    static let cellHeight: CGFloat = 16

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        let lineView = ThemedView()
        lineView.kind = .separator

        contentView.addAutoLayoutSubview(lineView)
        lineView.vc
            .horizontalEdges()
            .bottom()
            .height(by: type(of: self).lineHeight)
    }
}
