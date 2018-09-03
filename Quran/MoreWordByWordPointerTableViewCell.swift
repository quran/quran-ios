//
//  MoreWordByWordPointerTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/25/18.
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

class MoreWordByWordPointerTableViewCell: ThemedTableViewCell {
    override var themeTextLabel: Bool { return true }

    var onSwitchChanged: ((Bool) -> Void)?

    let switchControl = UISwitch()

    override func awakeFromNib() {
        super.awakeFromNib()
        kind = .popover
        separatorInset = .zero
        accessoryView = switchControl
        switchControl.addTarget(self, action: #selector(switchChanged), for: .valueChanged)
    }

    @objc
    private func switchChanged() {
        onSwitchChanged?(switchControl.isOn)
    }
}
