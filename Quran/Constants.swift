//
//  Constants.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/20/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
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

enum Layout { }
extension Layout {
    enum Translation { }
    enum QuranCell { }
}

extension Layout {
    // we are using window's layoutMargins to prevent the margin to change while scrolling
    static var windowDirectionalLayoutMargins: DirectionalEdgeInsets {
        return UIApplication.shared.keyWindow?.directionalLayoutMarginsiOS9 ?? .zero
    }

    static var windowDirectionalSafeAreaInsets: DirectionalEdgeInsets {
        return UIApplication.shared.keyWindow?.directionalSafeAreaInsets ?? .zero
    }
}

extension Layout.Translation {
    static let horizontalInset: CGFloat = 7
}

extension Layout.QuranCell {
    /// This margin is used between the pages so that we can show
    /// a separator (horizontal line) between them.
    static let horizontalInset: CGFloat = 5
}
