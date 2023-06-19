//
//  AudioPlayBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import UIKit

class AudioPlayBarView: UIView {
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

    @IBOutlet var stopButton: UIButton!
    @IBOutlet var previousButton: UIButton!
    @IBOutlet var pauseResumeButton: UIButton!
    @IBOutlet var nextButton: UIButton!
    @IBOutlet var moreButton: UIButton!

    // MARK: Private

    private func setUp() {
        loadViewFrom(nibName: "AudioPlayBarView", bundle: .module)
    }
}
