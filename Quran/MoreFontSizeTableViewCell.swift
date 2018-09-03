//
//  MoreFontSizeTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/29/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
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

class MoreFontSizeTableViewCell: ThemedTableViewCell {

    var onIncreaseTapped: (() -> Void)?
    var onDecreaseTapped: (() -> Void)?

    @IBOutlet weak var increase: ThemedButton!
    @IBOutlet weak var decrease: ThemedButton!
    @IBOutlet weak var separator: ThemedView!

    override func awakeFromNib() {
        super.awakeFromNib()
        kind = .popover
        separator.kind = .popoverSeparator
        separatorInset = .zero
        for button in [increase, decrease] {
            button?.kind = .label
            button?.disabledKind = .labelVeryWeak
        }
        increase.setTitle(l("menu.fontSizeLetter"), for: .normal)
        decrease.setTitle(l("menu.fontSizeLetter"), for: .normal)
    }

    @IBAction func increaseTapped(_ sender: Any) {
        onIncreaseTapped?()
    }

    @IBAction func decreaseTapped(_ sender: Any) {
        onDecreaseTapped?()
    }
}
