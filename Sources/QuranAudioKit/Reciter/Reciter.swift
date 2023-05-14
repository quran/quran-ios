//
//  Reciter.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/27/16.
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

import Foundation
import Localization

public enum AudioType: Hashable, Sendable {
    case gapless(databaseName: String)
    case gapped
}

public struct Reciter: Hashable, Sendable {
    public let id: Int
    public let nameKey: String
    let directory: String
    let audioURL: URL
    let audioType: AudioType
    let hasGaplessAlternative: Bool
    public let category: Category

    // TODO: Add arabicTafseer
    public enum Category: String, Sendable {
        case arabic
        case english
        case arabicEnglish
    }
}

extension Reciter {
    public var localizedName: String {
        l(nameKey, table: .readers)
    }
}
