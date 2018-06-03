//
//  MoreArabicTranslationTableViewCell.swift
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

class MoreArabicTranslationTableViewCell: ThemedTableViewCell {
    var onSegmentChanged: ((Int) -> Void)?

    @IBOutlet weak var segmentedControl: UISegmentedControl!

    override func awakeFromNib() {
        super.awakeFromNib()
        kind = .popover
        separatorInset = .zero
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        segmentedControl?.setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
            ], for: .normal)
        segmentedControl?.setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 16),
            NSAttributedStringKey.foregroundColor: UIColor.white
            ], for: .selected)
    }

    @objc
    private func segmentChanged() {
        onSegmentChanged?(segmentedControl.selectedSegmentIndex)
    }
}
