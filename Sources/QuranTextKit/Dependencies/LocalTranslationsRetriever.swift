//
//  LocalTranslationsRetriever.swift
//
//
//  Created by Mohamed Afifi on 2021-12-17.
//

import PromiseKit
import TranslationService

/// @mockable
protocol LocalTranslationsRetriever {
    func getLocalTranslations() -> Promise<[Translation]>
}

extension TranslationService.LocalTranslationsRetriever: LocalTranslationsRetriever { }
