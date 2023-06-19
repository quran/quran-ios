//
//  AudioReciterBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//

import UIKit
import UIx

class AudioReciterBarView: UIView {
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

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var backgroundButton: BackgroundColorButton!

    // MARK: Private

    private func setUp() {
        backgroundColor = .clear
        loadViewFrom(nibName: "AudioReciterBarView", bundle: .module)
    }
}
