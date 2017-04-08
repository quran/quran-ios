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

import UIKit

class QuranTranslationSuraNameCollectionViewCell: QuranTranslationBaseCollectionViewCell {
    let label: UILabel = UILabel()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        let colorView = UIView()
        colorView.backgroundColor = #colorLiteral(red: 0.08235294118, green: 0.3215686275, blue: 0.3411764706, alpha: 1)
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 28)
        label.textColor = .white

        contentView.addAutoLayoutSubview(colorView)
        contentView.pinParentAllDirections(colorView)

        colorView.addAutoLayoutSubview(label)
        colorView.pinParentAllDirections(label,
                                         leadingValue: Layout.Translation.horizontalInset,
                                         trailingValue: Layout.Translation.horizontalInset,
                                         topValue: 15,
                                         bottomValue: 15)
    }
}
