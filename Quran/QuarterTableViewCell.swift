//
//  QuarterTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
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

class QuarterTableViewCell: UITableViewCell {

    @IBOutlet weak var circleView: CircleView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var startPage: UILabel!
    @IBOutlet weak var circleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        circleView.fillColor = UIColor.appIdentity()
        circleView.emptyColor = #colorLiteral(red: 0.5411764706, green: 0.6901960784, blue: 0.6156862745, alpha: 1)
    }
}
