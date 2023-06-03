//
//  TranslationNetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import BatchDownloader

struct TranslationNetworkManager {
    static let path = "/data/translations.php"

    let networkManager: NetworkManager
    let parser: TranslationsParser

    func getTranslations() async throws -> [Translation] {
        let data = try await networkManager.request(Self.path, parameters: [("v", "5")])
        return try parser.parse(data)
    }
}
