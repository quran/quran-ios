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

    func setUp() {
        loadViewFromNib()
        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.layer.borderWidth = 0.5
    }

    func loadViewFromNib() {
        let nibName = "AudioQariBarView"
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

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.layer.masksToBounds = true
    }
}
