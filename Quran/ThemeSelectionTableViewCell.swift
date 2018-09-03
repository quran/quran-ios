//
//  ThemeSelectionTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 6/3/18.
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
class ThemeSelectionTableViewCell: ThemedTableViewCell {

    @IBOutlet weak var lightButton: ThemeButton!
    @IBOutlet weak var darkButton: ThemeButton!

    var onLightTapped: (() -> Void)?
    var onDarkTapped: (() -> Void)?

    override func awakeFromNib() {
        super.awakeFromNib()
        kind = .popover
        lightButton.color = .white
        darkButton.color = #colorLiteral(red: 0.07289864868, green: 0.07289864868, blue: 0.07289864868, alpha: 1)
    }

    @IBAction func lightTapped(_ sender: Any) {
        onLightTapped?()
    }

    @IBAction func darkTapped(_ sender: Any) {
        onDarkTapped?()
    }

    var darkSelected: Bool = false {
        didSet {
            darkButton.layer.borderWidth  = darkSelected ? 2 : 0
            lightButton.layer.borderWidth = darkSelected ? 0 : 2
        }
    }
}

class ThemeButton: ThemedButton {
    var color: UIColor = .red
    var highlightedColor: UIColor = .gray

    override func awakeFromNib() {
        super.awakeFromNib()
        borderKind = .appTint
        layer.masksToBounds = true
    }

    private var oldSize: CGSize?

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = circularRadius

        guard oldSize != bounds.size else { return }
        setImage(color.image(size: bounds.size), for: .normal)
        setImage(highlightedColor.image(size: bounds.size), for: .highlighted)
        oldSize = bounds.size
    }
}
