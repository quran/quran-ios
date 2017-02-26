//
//  Translation.swift
//  Quran
//
//  Created by Ahmed El-Helw on 2/13/16.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import Foundation

struct Translation {
    let id: Int
    let displayName: String
    let translator: String?
    let translatorForeign: String?
    let fileName: String
    let version: Int
    var installedVersion: Int?
}
