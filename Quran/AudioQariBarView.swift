//
//  AudioQariBarView.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/8/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class AudioQariBarView: UIView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var backgroundButton: BackgroundColorButton!

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    private func setUp() {
        loadViewFrom(nibName: "AudioQariBarView")
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.layer.borderWidth = 0.5
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.layer.masksToBounds = true
    }
}
