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

import UIKit

class TranslationTableViewCell: ThemedTableViewCell {

    @IBOutlet weak var checkbox: UIImageView!
    @IBOutlet weak var downloadButton: DownloadButton!
    @IBOutlet fileprivate weak var firstLabel: ThemedLabel!
    @IBOutlet fileprivate weak var secondLabel: UILabel!
    @IBOutlet fileprivate weak var languageLabel: ThemedLabel!
    @IBOutlet weak var iPhoneIcon: UIImageView!

    var onShouldCancelDownload: (() -> Void)?
    var onShouldStartDownload: (() -> Void)?

    override func awakeFromNib() {
        firstLabel.kind = .labelStrong
        languageLabel.kind = .appTint
        super.awakeFromNib()
        downloadButton.backgroundColor = .clear
        downloadButton.onButtonTapped = { [weak self] _ in
            self?.downloadButtonTapped()
        }
    }

    override func themeDidChange() {
        super.themeDidChange()
        translation.map { configure(with: $0) }
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
            image = #imageLiteral(resourceName: "checkbox-selected").withRenderingMode(.alwaysTemplate)
        } else {
            image = #imageLiteral(resourceName: "checkbox-unselected").withRenderingMode(.alwaysOriginal)
        }
        checkbox.image = image
    }

    private var translation: Translation? {
        didSet {
            guard let translation = translation else {
                return
            }

            // show iPhone icon if the translation language is the same as device language
            // Always hide the icon
            iPhoneIcon.isHidden = true // Locale.current.languageCode != translation.languageCode
            firstLabel.text = translation.displayName
            languageLabel.text = Locale(identifier: translation.languageCode).localizedString(forLanguageCode: translation.languageCode)

            let translatorNameOptional = translation.translatorForeign ?? translation.translator

            guard let translatorName = translatorNameOptional, !translatorName.isEmpty else {
                secondLabel.attributedText = NSAttributedString()
                return
            }

            let translator = l("translatorLabel: ")

            let lightFont = UIFont.systemFont(ofSize: 15, weight: .light)
            let regularFont = translation.preferredTranslatorNameFont(ofSize: .medium)

            let lightColor = Theme.Kind.labelWeak.color
            let regularColor = Theme.Kind.labelStrong.color

            let lightAttributes: [NSAttributedStringKey: Any] = [.font: lightFont, .foregroundColor: lightColor]
            let regularAttributes: [NSAttributedStringKey: Any] = [.font: regularFont, .foregroundColor: regularColor]

            let translatorAttributes = NSMutableAttributedString(string: translator, attributes: lightAttributes)
            let attributes = NSAttributedString(string: translatorName, attributes: regularAttributes)
            translatorAttributes.append(attributes)
            secondLabel.attributedText = translatorAttributes
        }
    }
}

extension TranslationTableViewCell {

    func configure(with translation: Translation) {
        self.translation = translation
    }
}
