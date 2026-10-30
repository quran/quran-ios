//
//  ContentTranslationTestFixtures.swift
//
//
//  Created by Mohamed Afifi on 2026-10-30.
//

import AnnotationsService
import Foundation
import QuranText
import QuranTextKit
import TranslationService
@testable import QuranTranslationFeature

/// A view model whose data services find no files, so tests commit content directly.
@MainActor
func makeContentTranslationViewModel(overlayService: VerseOverlayService = .init()) -> ContentTranslationViewModel {
    let unavailableURL = URL(fileURLWithPath: "/tmp/unavailable-quran-translation-test")
    return ContentTranslationViewModel(
        localTranslationsRetriever: .init(databasesURL: unavailableURL),
        dataService: .init(databasesURL: unavailableURL, quranFileURL: unavailableURL),
        overlayService: overlayService
    )
}

func makeTranslation(id: Translation.ID) -> Translation {
    Translation(
        id: id,
        displayName: "Translation \(id)",
        translator: nil,
        translatorForeign: nil,
        fileURL: URL(string: "https://example.com/translation-\(id).zip")!,
        fileName: "translation-\(id).db",
        languageCode: "en",
        version: 1
    )
}

func makeVerseText(translationCount: Int, text: (Int) -> String = { "Translation \($0)" }) -> VerseText {
    VerseText(
        arabicText: "Arabic",
        translations: (0 ..< translationCount).map { index in
            .string(.init(
                text: text(index),
                quranRanges: [],
                footnoteRanges: [],
                footnotes: []
            ))
        },
        arabicPrefix: [],
        arabicSuffix: []
    )
}

/// Runs the view model's scrolls, which it defers to the next main-queue turn.
func drainMainQueue() async {
    await withCheckedContinuation { continuation in
        DispatchQueue.main.async { continuation.resume() }
    }
}
