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

protocol TranslationsParser {
    func parse(_ data: Data) throws -> [Translation]
}

struct JSONTranslationsParser: TranslationsParser {
    func parse(_ data: Data) throws -> [Translation] {
        let decoder = JSONDecoder()
        let decodedResponse = try decoder.decode(TranslationsResponse.self, from: data)
        let translations = decodedResponse.data.map { Translation($0) }
        return translations
    }
}

private struct TranslationsResponse: Decodable {
    let data: [TranslationResponse]
}

private struct TranslationResponse: Decodable {
    let id: Int
    let displayName: String
    let translator: String?
    let translatorForeign: String?
    let fileUrl: URL
    let fileName: String
    let languageCode: String
    let currentVersion: Int
}

private extension Translation {
    init(_ response: TranslationResponse) {
        self.init(id: response.id,
                  displayName: response.displayName,
                  translator: response.translator,
                  translatorForeign: response.translatorForeign,
                  fileURL: response.fileUrl,
                  fileName: response.fileName,
                  languageCode: response.languageCode,
                  version: response.currentVersion,
                  installedVersion: nil)
    }
}
