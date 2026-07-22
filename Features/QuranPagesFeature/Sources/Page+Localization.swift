//
//  Page+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-19.
//

import Caching
import Foundation
import NoorUI
import QuranKit
import QuranTextKit

extension Page {
    // TODO: Remove
    public func suraNames() -> NSAttributedString {
        let suras = verses.map(\.sura).orderedUnique()
        return suras.reduce(NSMutableAttributedString()) { fullString, sura in
            if fullString.length > 0 {
                fullString.append(NSAttributedString(string: " - "))
            }
            let suraString = attributedString(of: sura, fontSize: 14)
            fullString.append(suraString)
            return fullString
        }
    }

    public func suraNames() -> MultipartText {
        let suras = verses.map(\.sura).orderedUnique()
        let textArray: [MultipartText] = suras.map { "\(sura: $0)" }

        var result: MultipartText = ""
        for (index, text) in textArray.enumerated() {
            if index == 0 {
                result.append(text)
            } else {
                result.append(" - \(text)")
            }
        }
        return result
    }
}

extension Page: @retroactive Pageable { }
