//
//  JuzTableViewHeaderFooterView.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class JuzTableViewHeaderFooterView: UITableViewHeaderFooterView {

    let titleLabel: UILabel = UILabel()
    let subtitleLabel: UILabel = UILabel()

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

        titleLabel.textColor = UIColor(rgb: 0x323232)
        titleLabel.font = UIFont.boldSystemFontOfSize(15)
        contentView.addAutoLayoutSubview(titleLabel)
        contentView.pinParentVertical(titleLabel)
        contentView.addParentLeadingConstraint(titleLabel, value: 20)

        subtitleLabel.textColor = UIColor(rgb: 0x4B4B4B)
        subtitleLabel.font = UIFont.systemFontOfSize(12)
        subtitleLabel.textAlignment = .Right
        contentView.addAutoLayoutSubview(subtitleLabel)
        contentView.pinParentVertical(subtitleLabel)
        contentView.addParentTrailingConstraint(subtitleLabel, value: 10)
    }
}
