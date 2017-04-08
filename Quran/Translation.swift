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

struct Translation: Equatable {
    let id: Int
    let displayName: String
    let translator: String?
    let translatorForeign: String?
    let fileURL: URL
    let fileName: String
    let languageCode: String
    let version: Int
    var installedVersion: Int?

    static func == (lhs: Translation, rhs: Translation) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Translation {

    var possibleFileNames: [String] {
        let raw = rawFileName
        if raw != fileName {
            return [fileName, raw]
        }
        return [fileName]
    }

    var rawFileName: String {
        if fileURL.absoluteString.hasSuffix(Files.translationCompressedFileExtension) {
            return fileName.stringByDeletingPathExtension.stringByAppendingExtension(Files.translationCompressedFileExtension)
        }
        return fileName
    }

    var translationName: String {
        return translatorForeign ?? translator ?? displayName
    }
}
