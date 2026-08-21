//
//  QuranText+AyahMarkers.swift
//

import QuranText

extension QuranText {
    var ayahMarkerRanges: [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var markerStart: String.Index?

        for index in text.indices {
            if text[index].isArabicIndicDigit {
                markerStart = markerStart ?? index
            } else if let start = markerStart {
                ranges.append(start ..< index)
                markerStart = nil
            }
        }
        if let markerStart {
            ranges.append(markerStart ..< text.endIndex)
        }
        return ranges
    }
}

private extension Character {
    var isArabicIndicDigit: Bool {
        unicodeScalars.allSatisfy { (0x0660 ... 0x0669).contains($0.value) }
    }
}
