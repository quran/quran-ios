//
//  AyahMenuBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/11/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import AppDependencies
#if QURAN_SYNC
    import BookmarksFeature
#endif
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

public struct AyahMenuInput {
    // MARK: Lifecycle

    public init(
        sourceView: UIView,
        pointInView: CGPoint,
        verses: [AyahNumber],
        notes: [QuranAnnotations.Note],
        noteCount: Int = 0,
        highlightColor: HighlightColor? = nil
    ) {
        self.sourceView = sourceView
        self.pointInView = pointInView
        self.verses = verses
        self.notes = notes
        self.noteCount = noteCount
        self.highlightColor = highlightColor
        #if QURAN_SYNC
            isCollectionBookmarked = false
        #endif
    }

    #if QURAN_SYNC
        public init(
            sourceView: UIView,
            pointInView: CGPoint,
            verses: [AyahNumber],
            notes: [QuranAnnotations.Note],
            noteCount: Int = 0,
            highlightColor: HighlightColor? = nil,
            isCollectionBookmarked: Bool
        ) {
            self.sourceView = sourceView
            self.pointInView = pointInView
            self.verses = verses
            self.notes = notes
            self.noteCount = noteCount
            self.highlightColor = highlightColor
            self.isCollectionBookmarked = isCollectionBookmarked
        }
    #endif

    // MARK: Internal

    let sourceView: UIView
    let pointInView: CGPoint
    let verses: [AyahNumber]
    let notes: [QuranAnnotations.Note]
    let noteCount: Int
    let highlightColor: HighlightColor?
    #if QURAN_SYNC
        let isCollectionBookmarked: Bool
    #endif
}

@MainActor
public struct AyahMenuBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: AyahMenuListener, input: AyahMenuInput) -> UIViewController {
        let textRetriever = ShareableVerseTextRetriever(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )
        let noteService = container.noteService()
        #if QURAN_SYNC
            let deps = AyahMenuViewModel.Deps(
                sourceView: input.sourceView,
                pointInView: input.pointInView,
                verses: input.verses,
                notes: input.notes,
                noteService: noteService,
                textRetriever: textRetriever,
                highlightColor: input.highlightColor,
                usesSyncedNotes: usesSyncedNotes,
                noteCount: input.noteCount,
                isCollectionBookmarked: input.isCollectionBookmarked,
                ayahBookmarkCollectionService: container.syncService.map { AyahBookmarkCollectionService(syncService: $0) }
            )
        #else
            let deps = AyahMenuViewModel.Deps(
                sourceView: input.sourceView,
                pointInView: input.pointInView,
                verses: input.verses,
                notes: input.notes,
                noteService: noteService,
                textRetriever: textRetriever,
                highlightColor: input.highlightColor
            )
        #endif
        let viewModel = AyahMenuViewModel(deps: deps)
        viewModel.listener = listener
        return AyahMenuViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies

    private var usesSyncedNotes: Bool {
        #if QURAN_SYNC
            return container.mobileSyncNoteService() != nil
        #else
            return false
        #endif
    }
}
