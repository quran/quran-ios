//
//  Translation.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/16.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

private let `extension` = "zip"

struct Translation {
    let id: Int
    let displayName: String
    let translator: String?
    let translatorForeign: String?
    let fileURL: URL
    let fileName: String
    let version: Int
    var installedVersion: Int?
}

extension Translation {

    var possibleFileNames: [String] {
        if rawFileName != fileName {
            return [fileName, fileName.stringByDeletingPathExtension.stringByAppendingExtension(`extension`)]
        }
        return [fileName]
    }

    var rawFileName: String {
        if fileURL.absoluteString.hasSuffix(`extension`) {
            return fileName.stringByDeletingPathExtension.stringByAppendingExtension(`extension`)
        }
        return fileName
    }
}
