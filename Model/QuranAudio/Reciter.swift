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

public enum AudioType: Hashable, Sendable {
    case gapless(databaseName: String)
    case gapped
}

public struct Reciter: Hashable, Sendable {
    // MARK: Lifecycle

    public init(id: Int, nameKey: String, directory: String, audioURL: URL, audioType: AudioType, hasGaplessAlternative: Bool, category: Category) {
        self.id = id
        self.nameKey = nameKey
        self.directory = directory
        self.audioURL = audioURL
        self.audioType = audioType
        self.hasGaplessAlternative = hasGaplessAlternative
        self.category = category
    }

    // MARK: Public

    // TODO: Add arabicTafseer
    public enum Category: String, Sendable {
        case arabic
        case english
        case arabicEnglish
    }

    public let id: Int
    public let nameKey: String
    public let audioURL: URL
    public let audioType: AudioType
    public let hasGaplessAlternative: Bool
    public let category: Category

    // MARK: Internal

    let directory: String
}
