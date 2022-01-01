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
    let networkManager: NetworkManager
    let parser: TranslationsParser

    func getTranslations() -> Promise<[Translation]> {
        networkManager.request("/data/translations.php", parameters: [("v", "4")])
            .map(parser.parse)
    }
}
