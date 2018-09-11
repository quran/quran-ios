//
//  MoreRotationTableViewCell.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/9/18.
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

class MoreRotationTableViewCell: ThemedTableViewCell {

    @IBOutlet weak var portrait: ThemedButton!
    @IBOutlet weak var landscape: ThemedButton!
    @IBOutlet weak var separator: ThemedView!

    override func awakeFromNib() {
        super.awakeFromNib()
        kind = .popover
        separator.kind = .popoverSeparator
        separatorInset = .zero
        for button in [portrait, landscape] {
            button?.kind = .label
            button?.disabledKind = .labelVeryWeak
        }
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(setOrientation), name: .UIDeviceOrientationDidChange, object: nil)
        setOrientation()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    @objc
    private func setOrientation() {
        let orientation = UIApplication.shared.statusBarOrientation
        portrait.isEnabled = orientation.isLandscape
        landscape.isEnabled = orientation.isPortrait
    }

    @IBAction func portraitTapped(_ sender: Any) {
        guard !UIApplication.shared.statusBarOrientation.isPortrait else {
            return
        }
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }

    @IBAction func landscapeTapped(_ sender: Any) {
        guard !UIApplication.shared.statusBarOrientation.isLandscape else {
            return
        }
        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
    }
}
