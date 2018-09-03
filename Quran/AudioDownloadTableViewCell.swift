//
//  AudioDownloadTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/17/17.
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

class AudioDownloadTableViewCell: ThemedTableViewCell {

    fileprivate static var formatter: ByteCountFormatter = {
        return ByteCountFormatter()
    }()

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var downloadButton: DownloadButton!
    @IBOutlet fileprivate weak var firstLabel: ThemedLabel!
    @IBOutlet fileprivate weak var secondLabel: ThemedLabel!

    var onShouldCancelDownload: (() -> Void)?
    var onShouldStartDownload: (() -> Void)?

    override func awakeFromNib() {
        firstLabel.kind = .labelStrong
        secondLabel.kind = .labelWeak
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

    override func setEditing(_ editing: Bool, animated: Bool) {
        downloadButton.isHidden = editing
        super.setEditing(editing, animated: animated)
    }
}

extension AudioDownloadTableViewCell {

    func configure(with download: QariAudioDownload) {
        photoImageView.image = UIImage(named: download.qari.imageName)
        firstLabel.text = download.qari.name

        let suraCount = download.downloadedSuraCount
        let size = Int64(download.downloadedSizeInBytes)
        let filesDownloadedFormat = lAndroid("files_downloaded")
        let filesDownloaded = String(format: filesDownloadedFormat, suraCount)
        secondLabel.text = "\(type(of: self).formatter.string(fromByteCount: size)) - \(filesDownloaded)"
    }
}
