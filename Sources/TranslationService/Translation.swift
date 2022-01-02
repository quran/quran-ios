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

public struct Translation: Hashable {
    public let id: Int
    public let displayName: String
    public let translator: String?
    public let translatorForeign: String?
    public let fileURL: URL
    public let fileName: String
    public let languageCode: String
    let version: Int
    var installedVersion: Int?

    public var isDownloaded: Bool { installedVersion != nil }
    public var needsUpgrade: Bool { installedVersion != version }

    public var localURL: URL {
        Self.localTranslationsURL.appendingPathComponent(fileName)
    }
}

extension Translation {
    static let compressedFileExtension = "zip"

    var possibleFileNames: [String] {
        let raw = rawFileName
        if raw != fileName {
            return [fileName, raw]
        }
        return [fileName]
    }

    var rawFileName: String {
        if fileURL.absoluteString.hasSuffix(Self.compressedFileExtension) {
            return fileName.stringByDeletingPathExtension.stringByAppendingExtension(Self.compressedFileExtension)
        }
        return fileName
    }

    public var translationName: String {
        translatorForeign ?? translator ?? displayName
    }
}
