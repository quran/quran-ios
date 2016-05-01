//
//  QuarterTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
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
        circleView.emptyColor = UIColor(rgb: 0x8AB09D)
    }

}
