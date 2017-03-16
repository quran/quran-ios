//
//  Translation.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/16.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct Translation: Equatable {
    let id: Int
    let displayName: String
    let translator: String?
    let translatorForeign: String?
    let fileURL: URL
    let fileName: String
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
}
