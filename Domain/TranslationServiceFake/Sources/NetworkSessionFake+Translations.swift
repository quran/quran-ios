//
//  NetworkSessionFake+Translations.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation
import NetworkSupportFake
import QuranText
@testable import NetworkSupport
@testable import TranslationService

extension NetworkSessionFake {
    /// Makes the translations endpoint at `baseURL` list `translations` at their `version`.
    public func respondWithTranslations(_ translations: [Translation], baseURL: URL) throws {
        let response = TranslationsResponse(data: translations.map(TranslationResponse.init))
        let request = NetworkManager.request(
            baseURL: baseURL,
            path: TranslationNetworkManager.path,
            parameters: [("v", "5")]
        )
        dataResults[request.url!] = .success(try JSONEncoder().encode(response))
    }
}

private extension TranslationResponse {
    init(_ translation: Translation) {
        self.init(
            id: translation.id,
            displayName: translation.displayName,
            translator: translation.translator,
            translatorForeign: translation.translatorForeign,
            fileUrl: translation.fileURL,
            fileName: translation.fileName,
            languageCode: translation.languageCode,
            currentVersion: translation.version
        )
    }
}
