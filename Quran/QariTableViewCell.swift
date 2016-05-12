//
//  QariTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/12/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class QariTableViewCell: UITableViewCell {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        photoImageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        photoImageView.layer.borderWidth = 0.5

        let selectionBackground = UIView()
        selectionBackground.backgroundColor = UIColor(rgb: 0xE9E9E9)
        selectedBackgroundView = selectionBackground
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        photoImageView.layer.cornerRadius = photoImageView.bounds.width / 2
        photoImageView.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        accessoryType = selected ? .Checkmark : .None
        updateSelectedBackgroundView()
    }

    override func setHighlighted(highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        updateSelectedBackgroundView()
    }

    private func updateSelectedBackgroundView() {
//        selectedBackgroundView?.hidden = selected || !highlighted
    }
}
