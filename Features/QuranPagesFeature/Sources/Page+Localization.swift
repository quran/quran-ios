//
//  Page+Localization.swift
//
//
//  Created by Mohamed Afifi on 2023-06-19.
//

import Caching
import NoorUI
import QuranKit
import QuranTextKit

extension Page {
    public func suraNames() -> MultipartText {
        let suras = verses.map(\.sura).orderedUnique()
        let textArray: [MultipartText] = suras.map { "\(sura: $0)" }

        var result: MultipartText = ""
        for (index, text) in textArray.enumerated() {
            if index == 0 {
                result.append(text)
            } else {
                result.append(" · \(text)")
            }
        }
        return result
    }
}

extension Page: @retroactive Pageable { }
