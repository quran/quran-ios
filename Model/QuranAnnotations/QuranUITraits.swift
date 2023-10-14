//
//  QuranUITraits.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/29/21.
//  Copyright © 2021 Quran.com. All rights reserved.
//

import Foundation
import QuranKit
import QuranText

public struct QuranUITraits: Equatable {
    // MARK: Lifecycle

    public init() { }

    // MARK: Public

    public var highlights = QuranHighlights()

    public var translationFontSize: FontSize = .xSmall
    public var arabicFontSize: FontSize = .xSmall

    public mutating func removeHighlights() {
        highlights = QuranHighlights()
    }
}
