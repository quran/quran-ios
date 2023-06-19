//
//  AudioDownloadingBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import Localization
import UIKit

class AudioDownloadingBarView: UIView {
    // MARK: Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    // MARK: Internal

    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var infoLabel: UILabel!

    // MARK: Private

    private func setUp() {
        loadViewFrom(nibName: "AudioDownloadingBarView", bundle: .module)
        infoLabel.text = lAndroid("downloading_title")
    }
}
