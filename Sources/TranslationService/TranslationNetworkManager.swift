//
//  TranslationNetworkManager.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import BatchDownloader
import PromiseKit

protocol TranslationNetworkManager {
    func getTranslations() -> Promise<[Translation]>
}

struct DefaultTranslationNetworkManager: TranslationNetworkManager {
    static let path = "/data/translations.php"

    let networkManager: NetworkManager
    let parser: TranslationsParser

    func getTranslations() -> Promise<[Translation]> {
        networkManager.request(Self.path, parameters: [("v", "5")])
            .map(parser.parse)
    }
}
