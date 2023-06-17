//
//  QuranHighlightType+Theme.swift
//  Quran
//
//  Created by Mohamed Afifi on 10/7/18.
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

import QuranAnnotations
import UIKit

extension QuranHighlightType {
    public var color: UIColor {
        switch self {
        case .reading: return UIColor.appIdentity.withAlphaComponent(0.3)
        case .share: return UIColor.systemBlue.withAlphaComponent(0.3)
        case .note(let color): return color.uiColor.withAlphaComponent(0.5)
        case .search: return UIColor.systemGray.withAlphaComponent(0.5)
        case .word: return UIColor.appIdentity.withAlphaComponent(0.3)
        }
    }
}
