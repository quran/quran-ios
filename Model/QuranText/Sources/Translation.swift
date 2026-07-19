//
//  Translation.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/16.
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
import Utilities

public struct Translation: Hashable, Sendable {
    public typealias ID = Int

    // MARK: Lifecycle

    public init(id: ID, displayName: String, translator: String?, translatorForeign: String?, fileURL: URL, fileName: String, languageCode: String, version: Int, installedVersion: Int? = nil) {
        self.id = id
        self.displayName = displayName
        self.translator = translator
        self.translatorForeign = translatorForeign
        self.fileURL = fileURL
        self.fileName = fileName
        self.languageCode = languageCode
        self.version = version
        self.installedVersion = installedVersion
    }

    // MARK: Public

    public let id: ID
    public let displayName: String
    public let translator: String?
    public let translatorForeign: String?
    public let fileURL: URL
    public let fileName: String
    public let languageCode: String
    public let version: Int
    public var installedVersion: Int?

    public var isDownloaded: Bool { installedVersion != nil }
    public var needsUpgrade: Bool { installedVersion != version }

    public var translationName: String {
        translatorDisplayName ?? displayName
    }

    public var translatorDisplayName: String? {
        translatorForeign ?? translator
    }
}

extension Translation: Comparable {
    public static func < (lhs: Translation, rhs: Translation) -> Bool {
        let comparer = MultiPredicateComparer<Translation>(increasingOrderPredicates: [
            { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending },
            { $0.translationName.localizedStandardCompare($1.translationName) == .orderedAscending },
        ])
        return comparer.areInIncreasingOrder(lhs: lhs, rhs: rhs)
    }
}
