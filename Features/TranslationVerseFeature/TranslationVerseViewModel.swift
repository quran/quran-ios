//
//  TranslationVerseViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import Crashing
import Foundation
import QuranKit
import QuranTextKit
import QuranTranslationFeature
import VLogging

public struct TranslationVerseActions {
    // MARK: Lifecycle

    public init(updateCurrentVerseTo: @escaping (_: AyahNumber) -> Void) {
        self.updateCurrentVerseTo = updateCurrentVerseTo
    }

    // MARK: Internal

    let updateCurrentVerseTo: (_ verse: AyahNumber) -> Void
}

@MainActor
class TranslationVerseViewModel {
    // MARK: Lifecycle

    init(startingVerse: AyahNumber, dataService: QuranTextDataService, actions: TranslationVerseActions) {
        currentVerse = startingVerse
        self.dataService = dataService
        self.actions = actions
        retieveTranslatedVerse(verse: startingVerse)
    }

    // MARK: Internal

    @Published var translatedVerse: TranslatedVerse?

    @Published var currentVerse: AyahNumber {
        didSet {
            actions.updateCurrentVerseTo(currentVerse)
        }
    }

    func reload() {
        retieveTranslatedVerse(verse: currentVerse)
    }

    func next() {
        logger.info("Verse Translation: moving to next verse currentVerse:\(currentVerse)")
        if let next = currentVerse.next {
            retieveTranslatedVerse(verse: next)
        }
    }

    func previous() {
        logger.info("Verse Translation: moving to previous verse currentVerse:\(currentVerse)")
        if let previous = currentVerse.previous {
            retieveTranslatedVerse(verse: previous)
        }
    }

    // MARK: Private

    private let dataService: QuranTextDataService

    private let actions: TranslationVerseActions

    private func retieveTranslatedVerse(verse: AyahNumber) {
        currentVerse = verse
        Task {
            do {
                let texts = try await dataService.textForVerses([verse])
                let translations = Translations(texts.translations)
                let translatedVerse = zip([verse], texts.verses).map { verse, text in
                    TranslatedVerse(verse: verse, text: text, translations: translations)
                }

                updateTranslatedVerse(translatedVerse)
            } catch {
                // TODO: Show an error to the user
                crasher.recordError(error, reason: "Failed to retrieve translation text verse \(verse)")
            }
        }
    }

    private func updateTranslatedVerse(_ translatedVerses: [TranslatedVerse]) {
        translatedVerse = translatedVerses.first
    }
}
