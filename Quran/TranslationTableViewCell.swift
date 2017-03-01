//
//  TranslationTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/26/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit
import DownloadButton

class TranslationTableViewCell: UITableViewCell, PKDownloadButtonDelegate {

    @IBOutlet weak var downloadButton: PKDownloadButton!
    @IBOutlet weak var firstLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!

    var onShouldCancelDownload: (() -> Void)?
    var onShouldStartDownload: (() -> Void)?

    var response: DownloadNetworkResponse? {
        didSet {
            guard let response = response else {
                return
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        downloadButton.delegate = self

        downloadButton.stopDownloadButton.tintColor = .appIdentity()
        downloadButton.stopDownloadButton.filledLineStyleOuter = true
        downloadButton.pendingView.tintColor = .appIdentity()
        downloadButton.startDownloadButton.cleanDefaultAppearance()
        downloadButton.startDownloadButton.setTitle(nil, for: .normal)
        downloadButton.startDownloadButton.setImage(#imageLiteral(resourceName: "download-30").tintedImage(withColor: .appIdentity()), for: .normal)
    }

    func downloadButtonTapped(_ downloadButton: PKDownloadButton!, currentState state: PKDownloadButtonState) {
        switch state {
        case .startDownload:
            downloadButton.state = .pending
            downloadButton.pendingView.stopSpin()
            downloadButton.pendingView.startSpin()
            onShouldStartDownload?()
        case .pending:
            downloadButton.state = .startDownload
            onShouldCancelDownload?()
        case .downloading:
            downloadButton.state = .startDownload
            onShouldCancelDownload?()
        case .downloaded:
            onShouldCancelDownload?()
            downloadButton.state = .startDownload
        }
    }

    func set(title: String, subtitle: String) {
        firstLabel.text = title

        guard !subtitle.isEmpty else {
            secondLabel.attributedText = NSAttributedString()
            return
        }

        let translator = "Translator: "

        let lightFont = UIFont.systemFont(ofSize: 15, weight: UIFontWeightLight)
        let regularFont = UIFont.systemFont(ofSize: 17, weight: UIFontWeightRegular)

        let lightColor = #colorLiteral(red: 0.3921568627, green: 0.3921568627, blue: 0.3921568627, alpha: 1)
        let regularColor = #colorLiteral(red: 0.1960784314, green: 0.1960784314, blue: 0.1960784314, alpha: 1)

        let lightAttributes: [String: Any] = [NSFontAttributeName: lightFont, NSForegroundColorAttributeName: lightColor]
        let regularAttributes: [String: Any] = [NSFontAttributeName: regularFont, NSForegroundColorAttributeName: regularColor]

        let translatorAttributes = NSMutableAttributedString(string: translator, attributes: lightAttributes)
        let attributes = NSMutableAttributedString(string: subtitle, attributes: regularAttributes)
        translatorAttributes.append(attributes)
        secondLabel.attributedText = translatorAttributes
    }
}

extension PKDownloadButton {
    func setDownloadState(_ state: DownloadState) {
        isHidden = false
        switch state {
        case .notDownloaded:
            self.state = .startDownload
        case .pending:
            self.state = .pending
            pendingView.stopSpin()
            pendingView.startSpin()
        case .downloading(let progress):
            self.state = .downloading
            self.stopDownloadButton.progress = CGFloat(progress)
        case .downloaded:
            self.state = .startDownload
            isHidden = true
        }
    }
}
