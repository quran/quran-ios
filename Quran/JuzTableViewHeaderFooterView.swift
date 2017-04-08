//
//  JuzTableViewHeaderFooterView.swift
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

class JuzTableViewHeaderFooterView: UITableViewHeaderFooterView {

    let titleLabel: UILabel = UILabel()
    let subtitleLabel: UILabel = UILabel()

    let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer()

    var object: Any?

    var onTapped: (() -> Void)?

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setUp()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    fileprivate func setUp() {
        addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(onViewTapped))

        contentView.backgroundColor = UIColor(rgb: 0xEEEEEE)

        titleLabel.textColor = UIColor(rgb: 0x323232)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        contentView.addAutoLayoutSubview(titleLabel)
        contentView.pinParentVertical(titleLabel)
        contentView.addParentLeadingConstraint(titleLabel, value: 20)

        subtitleLabel.textColor = UIColor(rgb: 0x4B4B4B)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textAlignment = .right
        contentView.addAutoLayoutSubview(subtitleLabel)
        contentView.pinParentVertical(subtitleLabel)
        contentView.addParentTrailingConstraint(subtitleLabel, value: 10)
    }

    func onViewTapped() {
        onTapped?()
    }
}
