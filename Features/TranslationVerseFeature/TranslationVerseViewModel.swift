//
//  TranslationVerseViewModel.swift
//  Quran
//
//  Created by Mohamed Afifi on 2022-10-09.
//  Copyright © 2022 Quran.com. All rights reserved.
//

import AnnotationsService
import Combine
import QuranKit
import QuranText
import QuranTextKit
import QuranTranslationFeature
import TranslationService
import VLogging

public struct TranslationVerseActions {
    // MARK: Lifecycle

    public init(updateCurrentVerseTo: @escaping (AyahNumber) -> Void) {
        self.updateCurrentVerseTo = updateCurrentVerseTo
    }

    // MARK: Internal

    let updateCurrentVerseTo: (AyahNumber) -> Void
}

@MainActor
class TranslationVerseViewModel: ObservableObject {
    // MARK: Lifecycle

    init(startingVerse: AyahNumber, localTranslationsRetriever: LocalTranslationsRetriever, dataService: QuranTextDataService, actions: TranslationVerseActions) {
        currentVerse = startingVerse
        self.dataService = dataService
        self.actions = actions

        let noOpHighlightingService = QuranHighlightsService()
        translationViewModel = ContentTranslationViewModel(localTranslationsRetriever: localTranslationsRetriever, dataService: dataService, highlightsService: noOpHighlightingService)
        translationViewModel.showHeaderAndFooter = false
        translationViewModel.verses = [startingVerse]
    }

    // MARK: Internal

    private var cancellables: Set<AnyCancellable> = []

    let translationViewModel: ContentTranslationViewModel

    @Published var currentVerse: AyahNumber {
        didSet {
            translationViewModel.verses = [currentVerse]
            actions.updateCurrentVerseTo(currentVerse)
        }
    }

    func next() {
        logger.info("Verse Translation: moving to next verse currentVerse:\(currentVerse)")
        if let next = currentVerse.next {
            currentVerse = next
        }
    }

    func previous() {
        logger.info("Verse Translation: moving to previous verse currentVerse:\(currentVerse)")
        if let previous = currentVerse.previous {
            currentVerse = previous
        }
    }

    // MARK: Private

    private let dataService: QuranTextDataService

    private let actions: TranslationVerseActions
}
