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
        verses = startingVerse.quran.verses
        self.localTranslationsRetriever = localTranslationsRetriever
        self.dataService = dataService
        self.actions = actions
    }

    // MARK: Internal

    let verses: [AyahNumber]

    @Published var currentVerse: AyahNumber {
        didSet {
            guard currentVerse != oldValue else {
                return
            }
            logger.info("Verse Translation: current verse changed to \(currentVerse.nonLocalizedDescription)")
            actions.updateCurrentVerseTo(currentVerse)
        }
    }

    func next() {
        logger.info("Verse Translation: moving to next verse currentVerse:\(currentVerse.nonLocalizedDescription)")
        if let next = currentVerse.next {
            currentVerse = next
        }
    }

    func previous() {
        logger.info("Verse Translation: moving to previous verse currentVerse:\(currentVerse.nonLocalizedDescription)")
        if let previous = currentVerse.previous {
            currentVerse = previous
        }
    }

    func translationViewModel(for verse: AyahNumber) -> ContentTranslationViewModel {
        let viewModel = ContentTranslationViewModel(
            localTranslationsRetriever: localTranslationsRetriever,
            dataService: dataService,
            overlayService: overlayService
        )
        viewModel.showHeaderAndFooter = false
        viewModel.verses = [verse]
        return viewModel
    }

    // MARK: Private

    private let localTranslationsRetriever: LocalTranslationsRetriever
    private let dataService: QuranTextDataService
    private let overlayService = VerseOverlayService()
    private let actions: TranslationVerseActions
}
