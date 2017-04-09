//
//  TranslationsParser.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
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
import SwiftyJSON

struct TranslationsParser: Parser {
    func parse(_ from: JSON) throws -> [Translation] {
        let translations: [Translation] = try from["data"].parsableArrayParsed()
        return translations
    }
}

extension Translation: Parsable {
    init(json: JSON) throws {
        id = try json["id"].parsed()
        displayName = try json["displayName"].parsed()
        translator = json["translator"].string
        translatorForeign = json["translatorForeign"].string
        fileURL = try json["fileUrl"].parsed()
        fileName = try json["fileName"].parsed()
        languageCode = try json["languageCode"].parsed()
        version = try json["currentVersion"].parsed()
        installedVersion = nil
    }
}
