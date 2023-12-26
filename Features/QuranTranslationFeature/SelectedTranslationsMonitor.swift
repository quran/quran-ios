//
//  SelectedTranslationsMonitor.swift
//
//
//  Created by Mohamed Afifi on 2023-12-26.
//

import Caching
import Combine
import QuranKit
import TranslationService

final class SelectedTranslationsMonitor {
    // MARK: Lifecycle

    init(cache: Cache<Page, TranslatedPage>) {
        cancellable = selectedTranslationsPreferences.$selectedTranslations
            .sink { _ in cache.removeAllObjects() }
    }

    // MARK: Internal

    let selectedTranslationsPreferences = SelectedTranslationsPreferences.shared
    var cancellable: AnyCancellable?
}
