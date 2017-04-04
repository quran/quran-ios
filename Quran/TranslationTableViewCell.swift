//
//  TranslationTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationTableViewCell: UITableViewCell {

    @IBOutlet weak var checkbox: UIImageView!
    @IBOutlet weak var downloadButton: TranslationDownloadButton!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!

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
            image = #imageLiteral(resourceName: "checkbox-selected").withRenderingMode(.alwaysTemplate)
        } else {
            image = #imageLiteral(resourceName: "checkbox-unselected").withRenderingMode(.alwaysOriginal)
        }
        checkbox.image = image
    }
}

extension TranslationTableViewCell {

    func configure(with translation: Translation) {
        firstLabel.text = translation.displayName
        let translatorNameOptional = translation.translatorForeign ?? translation.translator

        guard let translatorName = translatorNameOptional, !translatorName.isEmpty else {
            secondLabel.attributedText = NSAttributedString()
            return
        }

        let translator = NSLocalizedString("translatorLabel: ", comment: "")

        let lightFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightLight)
        let regularFont = translation.preferredTranslatorNameFont

        let lightColor = #colorLiteral(red: 0.3921568627, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
        let regularColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)

        let lightAttributes: [String: Any] = [NSFontAttributeName: lightFont, NSForegroundColorAttributeName: lightColor]
        let regularAttributes: [String: Any] = [NSFontAttributeName: regularFont, NSForegroundColorAttributeName: regularColor]

        let translatorAttributes = NSMutableAttributedString(string: translator, attributes: lightAttributes)
        let attributes = NSAttributedString(string: translatorName, attributes: regularAttributes)
        translatorAttributes.append(attributes)
        secondLabel.attributedText = translatorAttributes
    }
}
