//
//  AudioDownloadingBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class AudioDownloadingBarView: UIView {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var infoLabel: UILabel!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        loadViewFrom(nibName: "AudioDownloadingBarView")
        infoLabel.text = NSLocalizedString("downloading_title", tableName: "Android", comment: "")
    }
}
