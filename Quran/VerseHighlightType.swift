//
//  VerseHighlightType.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
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

enum VerseHighlightType: Int {
    case reading
    case share
    case bookmark
}

extension VerseHighlightType {
    static let sortedTypes: [VerseHighlightType] = [.share, .reading, .bookmark]
}

extension VerseHighlightType {
    var color: UIColor {
        switch self {
        case .reading   : return UIColor.appIdentity().withAlphaComponent(0.25)
        case .share     : return UIColor.selection().withAlphaComponent(0.25)
        case .bookmark  : return UIColor.bookmark().withAlphaComponent(0.25)
        }
    }
}
