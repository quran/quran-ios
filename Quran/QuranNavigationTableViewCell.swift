//
//  QuranNavigationTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/18.
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

class QuranNavigationTableViewCell: ThemedTableViewCell {
    @IBOutlet weak var name: ThemedLabel!
    @IBOutlet weak var startPage: ThemedLabel!
    @IBOutlet weak var descriptionLabel: ThemedLabel!

    override func awakeFromNib() {
        name.kind = .labelStrong
        startPage.kind = .labelMedium
        descriptionLabel.kind = .labelWeak
        super.awakeFromNib()
    }
}
