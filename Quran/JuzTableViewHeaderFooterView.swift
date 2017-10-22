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

        contentView.backgroundColor = #colorLiteral(red: 0.9333333333, green: 0.9333333333, blue: 0.9333333333, alpha: 1)

        titleLabel.textColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        contentView.addAutoLayoutSubview(titleLabel)
        titleLabel.vc.verticalEdges()
        titleLabel.vc.leading(by: 20)

        subtitleLabel.textColor = #colorLiteral(red: 0.2941176471, green: 0.2941176471, blue: 0.2941176471, alpha: 1)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textAlignment = .right
        contentView.addAutoLayoutSubview(subtitleLabel)
        subtitleLabel.vc.verticalEdges()
        subtitleLabel.vc.trailing(by: 10)
    }

    @objc
    func onViewTapped() {
        onTapped?()
    }
}
