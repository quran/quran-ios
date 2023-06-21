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
import UIKit

extension Page {
    public func suraNames() -> NSAttributedString {
        let suras = verses.map(\.sura).orderedUnique()
        return suras.reduce(NSMutableAttributedString()) { fullString, sura in
            if fullString.length > 0 {
                fullString.append(NSAttributedString(string: " - "))
            }
            let suraString = attributedString(of: sura.localizedName(), arabicSuraName: sura.arabicSuraName, fontSize: 14)
            fullString.append(suraString)
            return fullString
        }
    }
}

extension Page: Pageable { }
