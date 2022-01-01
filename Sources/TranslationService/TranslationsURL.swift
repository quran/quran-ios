//
//  TranslationURLs.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation

extension Translation {
    static let translationsPathComponent = "translations"
    static let localTranslationsURL = FileManager.documentsURL.appendingPathComponent(translationsPathComponent)
}
