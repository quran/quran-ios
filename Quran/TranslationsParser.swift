//
//  TranslationsParser.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//  Copyright © 2017 Quran.com. All rights reserved.
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
        translatorForeign = json["translator_foreign"].string
        fileURL = try json["fileUrl"].parsed()
        fileName = try json["fileName"].parsed()
        version = try json["current_version"].parsed()
        installedVersion = nil
    }
}
