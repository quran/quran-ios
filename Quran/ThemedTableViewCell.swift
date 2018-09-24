//
//  ThemedTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/6/18.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2018  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UIKit

class ThemedTableViewCell: UITableViewCell {

    var themeTextLabel: Bool {
        return false
    }

    var themeDetailTextLabel: Bool {
        return false
    }

    var themeImageView: Bool {
        return false
    }

    open var kind: Theme.Kind = .cell {
        didSet { themeDidChange() }
    }

    open var selectedKind: Theme.Kind = .cellSelected {
        didSet { themeDidChange() }
    }

    open var textLabelKind: Theme.Kind = .label {
        didSet { themeDidChange() }
    }

    open var detailTextLabelKind: Theme.Kind = .label {
        didSet { themeDidChange() }
    }

    open var imageViewKind: Theme.Kind = .label {
        didSet { themeDidChange() }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUp()
    }

    private func setUp() {
        themeDidChange()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        themeDidChange()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        themeDidChange()
    }

    @objc
    func themeDidChange() {
        backgroundColor = kind.color
        contentView.backgroundColor = backgroundColor
        let selectedView = UIView()
        selectedView.backgroundColor = selectedKind.color
        selectedBackgroundView = selectedView

        if themeTextLabel {
            textLabel?.textColor = textLabelKind.color
        }

        if themeDetailTextLabel {
            detailTextLabel?.textColor = detailTextLabelKind.color
        }

        if themeImageView {
            imageView?.tintColor = imageViewKind.color
        }
    }
}
