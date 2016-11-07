//
//  AudioPlayBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class AudioPlayBarView: UIView {

    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var pauseResumeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton?
    @IBOutlet weak var repeatCountLabel: UILabel?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        loadViewFrom(nibName: "AudioPlayBarView")
    }
}
