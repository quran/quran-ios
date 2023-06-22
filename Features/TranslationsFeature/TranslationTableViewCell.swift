//
//  TranslationTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
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

import NoorUI
import UIKit

class TranslationTableViewCell: UITableViewCell {
    @IBOutlet var checkbox: UIImageView!
    @IBOutlet var downloadButton: DownloadButton!
    @IBOutlet var firstLabel: UILabel!
    @IBOutlet var secondLabel: UILabel!
    @IBOutlet var languageLabel: UILabel!
    @IBOutlet var iPhoneIcon: UIImageView!

    var onShouldCancelDownload: (() -> Void)?
    var onShouldStartDownload: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        downloadButton.backgroundColor = .clear
        downloadButton.onButtonTapped = { [weak self] _ in
            self?.downloadButtonTapped()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onShouldStartDownload = nil
        onShouldCancelDownload = nil
    }

    func downloadButtonTapped() {
        switch downloadButton.state {
        case .notDownloaded:
            downloadButton.state = .pendingDownloading
            onShouldStartDownload?()

        case .needsUpgrade:
            downloadButton.state = .pendingUpgrading
            onShouldStartDownload?()

        case .pendingDownloading, .downloading:
            downloadButton.state = .notDownloaded
            onShouldCancelDownload?()

        case .pendingUpgrading, .downloadingUpgrade:
            downloadButton.state = .needsUpgrade
            onShouldCancelDownload?()

        case .downloaded:
            break
        }
    }

    func setSelection(_ selected: Bool) {
        let image: UIImage
        if selected {
            image = NoorImage.checkboxSelected.uiImage.withRenderingMode(.alwaysTemplate)
        } else {
            image = NoorImage.checkboxUnselected.uiImage.withRenderingMode(.alwaysOriginal)
        }
        checkbox.image = image
    }
}
