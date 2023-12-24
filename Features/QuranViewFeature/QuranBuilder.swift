//
//  QuranBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import AudioBannerFeature
import AyahMenuFeature
import MoreMenuFeature
import NoteEditorFeature
import QuranContentFeature
import QuranKit
import ReadingService
import TranslationsFeature
import TranslationVerseFeature
import UIKit
import Utilities
import WordPointerFeature

@MainActor
public struct QuranBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(input: QuranInput) -> UIViewController {
        let highlightsService = QuranHighlightsService()

        let quran = ReadingPreferences.shared.reading.quran
        let pageBookmarkService = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        let interactorDeps = QuranInteractor.Deps(
            quran: quran,
            analytics: container.analytics,
            pageBookmarkService: pageBookmarkService,
            noteService: container.noteService(),
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            noteEditorBuilder: NoteEditorBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, highlightsService: highlightsService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources
        )
        let interactor = QuranInteractor(deps: interactorDeps, input: input)
        let viewController = QuranViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
