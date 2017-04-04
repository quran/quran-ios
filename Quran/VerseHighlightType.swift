//
//  VerseHighlightType.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/2/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
