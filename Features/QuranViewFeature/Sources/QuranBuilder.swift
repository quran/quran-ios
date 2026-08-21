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
#if QURAN_SYNC
import BookmarksFeature
#endif
import MoreMenuFeature
import NoorUI
import NoteEditorFeature
#if QURAN_SYNC
import NotesFeature
#endif
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

        let reading = ReadingPreferences.shared.reading
        let quran = reading.quran
        #if QURAN_SYNC
        let notesObserver = QuranNotesObserver(noteService: container.mobileSyncNoteService(), quran: quran)
        let syncedHighlightsObserver = QuranSyncedHighlightsObserver(
            ayahHighlightService: container.ayahHighlightService(),
            highlightsService: highlightsService
        )
        let syncedCollectionsObserver = QuranSyncedCollectionsObserver(
            service: container.ayahBookmarkCollectionService()
        )
        let readingBookmarkObserver = QuranReadingBookmarkObserver(
            service: container.readingBookmarkService(),
            quran: quran
        )
        let interactorDeps = QuranInteractor.Deps(
            quran: quran,
            highlightsService: highlightsService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, highlightsService: highlightsService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            notesObserver: notesObserver,
            ayahNotesBuilder: AyahNotesBuilder(container: container, quranFont: reading.quranFont),
            bookmarkAyahsBuilder: BookmarkAyahsBuilder(container: container),
            syncedHighlightsObserver: syncedHighlightsObserver,
            syncedCollectionsObserver: syncedCollectionsObserver,
            readingBookmarkObserver: readingBookmarkObserver
        )
        #else
        let pageBookmarkService = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        let noteService = container.noteService()
        let notesObserver = QuranNotesObserver(noteService: noteService, quran: quran)
        let interactorDeps = QuranInteractor.Deps(
            quran: quran,
            highlightsService: highlightsService,
            ayahMenuBuilder: AyahMenuBuilder(container: container),
            moreMenuBuilder: MoreMenuBuilder(),
            audioBannerBuilder: AudioBannerBuilder(container: container),
            wordPointerBuilder: WordPointerBuilder(container: container),
            contentBuilder: ContentBuilder(container: container, highlightsService: highlightsService),
            translationsSelectionBuilder: TranslationsListBuilder(container: container),
            translationVerseBuilder: TranslationVerseBuilder(container: container),
            resources: container.readingResources,
            notesObserver: notesObserver,
            noteEditorBuilder: NoteEditorBuilder(container: container, quranFont: reading.quranFont),
            analytics: container.analytics,
            pageBookmarkService: pageBookmarkService,
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
