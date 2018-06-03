//
//  ThemedNavigationController.swift
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

import UIKit

class ThemedNavigationController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)
        themeDidChange()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    func themeDidChange() {
        navigationBar.tintColor = .barButtonsTint
        navigationBar.barTintColor = .barsBackground
    }
}
