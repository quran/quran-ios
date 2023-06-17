//
//  TranslationsParser.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/23/17.
//

import Foundation
import QuranText

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

struct TranslationsResponse: Codable {
    let data: [TranslationResponse]
}

struct TranslationResponse: Codable {
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
        self.init(
            id: response.id,
            displayName: response.displayName,
            translator: response.translator,
            translatorForeign: response.translatorForeign,
            fileURL: response.fileUrl,
            fileName: response.fileName,
            languageCode: response.languageCode,
            version: response.currentVersion,
            installedVersion: nil
        )
    }
}
