//
//  QuranFont.swift
//

import NoorFont
import QuranKit

public enum QuranFont: Hashable {
    case uthmanicHafs
    case indoPak

    // MARK: Internal

    var fontName: FontName {
        switch self {
        case .uthmanicHafs:
            .uthmanicHafs
        case .indoPak:
            .indoPak
        }
    }
}

public extension Reading {
    var quranFont: QuranFont {
        self == .indoPak ? .indoPak : .uthmanicHafs
    }
}
