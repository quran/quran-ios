//
//  JuzTableViewHeaderFooterView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class JuzTableViewHeaderFooterView: UITableViewHeaderFooterView {

    let label: UILabel = UILabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    private func setUp() {
        contentView.backgroundColor = UIColor(rgb: 0xEEEEEE)
        label.textColor = UIColor(rgb: 0x323232)
        label.font = UIFont.boldSystemFontOfSize(15)
        contentView.addAutoLayoutSubview(label)
        contentView.pinParentAllDirections(label, leadingValue: 20, trailingValue: 20, topValue: 0, bottomValue: 0)
    }
}
