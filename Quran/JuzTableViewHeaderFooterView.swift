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
        _ = contentView.pinParentVertical(titleLabel)
        _ = contentView.addParentLeadingConstraint(titleLabel, value: 20)

        subtitleLabel.textColor = UIColor(rgb: 0x4B4B4B)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textAlignment = .right
        contentView.addAutoLayoutSubview(subtitleLabel)
        _ = contentView.pinParentVertical(subtitleLabel)
        _ = contentView.addParentTrailingConstraint(subtitleLabel, value: 10)
    }

    func onViewTapped() {
        onTapped?()
    }
}
