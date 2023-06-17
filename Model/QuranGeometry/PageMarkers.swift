//
//  PageMarkers.swift
//
//
//  Created by Mohamed Afifi on 2023-04-19.
//

import CoreGraphics
import QuranKit

public struct PageMarkers {
    // MARK: Lifecycle

    public init(suraHeaders: [SuraHeaderLocation], ayahNumbers: [AyahNumberLocation]) {
        self.suraHeaders = suraHeaders
        self.ayahNumbers = ayahNumbers
    }

    // MARK: Public

    public let suraHeaders: [SuraHeaderLocation]
    public let ayahNumbers: [AyahNumberLocation]
}
