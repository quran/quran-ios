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

    func setUp() {
        loadViewFromNib()
    }

    func loadViewFromNib() {
        let nibName = "AudioPlayBarView"
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let contentView = nib.instantiateWithOwner(self, options: nil).first as? UIView else {
            fatalError("Couldn't load '\(nibName).xib' as the first item should be a UIView subclass.")
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|",
            options: [], metrics: nil, views: ["view" : contentView]))
        addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|",
            options: [], metrics: nil, views: ["view" : contentView]))
    }

}
