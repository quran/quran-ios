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
import BookmarksFeature
import MoreMenuFeature
import NoteEditorFeature
import QuranContentFeature
import QuranKit
import ReadingService
import TranslationsFeature
import TranslationVerseFeature
import UIKit
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
        #if QURAN_SYNC
        let notesObserver = QuranNotesObserver(noteService: container.mobileSyncNoteService(), quran: quran)
        let syncedHighlightsObserver = QuranSyncedHighlightsObserver(
            ayahBookmarkCollectionService: AyahBookmarkCollectionService(quranDataService: container.quranDataService),
            highlightsService: highlightsService
        )
        let readingBookmarkObserver = QuranReadingBookmarkObserver(
            service: MobileSyncReadingBookmarkService(quranDataService: container.quranDataService),
            quran: quran
        )
        let interactorDeps = QuranInteractor.Deps(
            quran: quran,
            analytics: container.analytics,
            pageBookmarkService: pageBookmarkService,
            highlightsService: highlightsService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            bookmarkAyahsBuilder: BookmarkAyahsBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, highlightsService: highlightsService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            notesObserver: notesObserver,
            noteEditorBuilder: NoteEditorBuilder(container: container),
            syncedHighlightsObserver: syncedHighlightsObserver,
            readingBookmarkObserver: readingBookmarkObserver
        )
        #else
        let noteService = container.noteService()
        let notesObserver = QuranNotesObserver(noteService: noteService, quran: quran)
        let interactorDeps = QuranInteractor.Deps(
            quran: quran,
            analytics: container.analytics,
            pageBookmarkService: pageBookmarkService,
            highlightsService: highlightsService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            bookmarkAyahsBuilder: BookmarkAyahsBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, highlightsService: highlightsService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            notesObserver: notesObserver,
            noteEditorBuilder: NoteEditorBuilder(container: container),
            noteService: noteService
        )
        #endif
        let interactor = QuranInteractor(deps: interactorDeps, input: input)
        let viewController = QuranViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
