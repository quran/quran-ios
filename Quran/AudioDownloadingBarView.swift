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

    func setUp() {
        loadViewFromNib()
        infoLabel.text = NSLocalizedString("downloading_title", tableName: "Android", comment: "")
    }

    func loadViewFromNib() {
        let nibName = "AudioDownloadingBarView"
        let nib = UINib(nibName: nibName, bundle: nil)
        guard let contentView = nib.instantiate(withOwner: self, options: nil).first as? UIView else {
            fatalError("Couldn't load '\(nibName).xib' as the first item should be a UIView subclass.")
        }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
            options: [], metrics: nil, views: ["view" : contentView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
            options: [], metrics: nil, views: ["view" : contentView]))
    }
}
