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

    let titleLabel = ThemedLabel()
    let subtitleLabel = ThemedLabel()

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

        self.backgroundView = ThemedView()

        titleLabel.kind = .labelStrong
        titleLabel.font = UIFont.boldSystemFont(ofSize: 15)
        contentView.addAutoLayoutSubview(titleLabel)
        titleLabel.vc
            .verticalEdges()
            .leading(by: 20)

        subtitleLabel.kind = .labelMedium
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textAlignment = .right
        contentView.addAutoLayoutSubview(subtitleLabel)
        subtitleLabel.vc
            .verticalEdges()
            .trailing(by: 10)
    }

    @objc
    func onViewTapped() {
        onTapped?()
    }
}
