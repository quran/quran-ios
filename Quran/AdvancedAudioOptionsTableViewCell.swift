//
//  AdvancedAudioOptionsTableViewCell.swift
//  Quran
//
//  Created by Afifi, Mohamed on 2018-04-07.
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

class AdvancedAudioOptionsTableViewCell: ThemedTableViewCell {

    override var themeTextLabel: Bool { return true }
    override var themeDetailTextLabel: Bool { return true }

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabelKind = .labelWeak
    }
}
