//
//  QariTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
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

class QariTableViewCell: ThemedTableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: ThemedLabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.kind = .labelStrong
        photoImageView.layer.borderColor = Theme.Kind.readerImageBorder.color.cgColor
        photoImageView.layer.borderWidth = 0.5

        let selectionBackground = ThemedView()
        selectionBackground.kind = .labelExtremelyWeak
        selectedBackgroundView = selectionBackground
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        photoImageView.layer.cornerRadius = photoImageView.bounds.width / 2
        photoImageView.layer.masksToBounds = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .checkmark : .none
        updateSelectedBackgroundView()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateSelectedBackgroundView()
    }

    fileprivate func updateSelectedBackgroundView() {
//        selectedBackgroundView?.hidden = selected || !highlighted
    }
}
