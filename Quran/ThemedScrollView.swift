//
//  ThemedScrollView.swift
//  Quran
//
//  Created by Mohamed Afifi on 9/29/18.
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

class ThemedScrollView: UIScrollView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setUp()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
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

    @objc
    func themeDidChange() {
        indicatorStyle = themedScrollIndicatorStyle
    }
}

extension UIScrollView {
    var themedScrollIndicatorStyle: UIScrollView.IndicatorStyle {
        switch Theme.current {
        case .dark: return .white
        case .light: return .black
        }
    }
}
