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

    #if QURAN_SYNC
        public init(
            sourceView: UIView,
            pointInView: CGPoint,
            verses: [AyahNumber],
            noteCount: Int,
            highlightVerses: [AyahNumber: HighlightColor],
            highlightCollections: [AyahBookmarkCollection]
        ) {
            self.sourceView = sourceView
            self.pointInView = pointInView
            self.verses = verses
            self.noteCount = noteCount
            self.highlightVerses = highlightVerses
            self.highlightCollections = highlightCollections
        }
    #else
        public init(
            sourceView: UIView,
            pointInView: CGPoint,
            verses: [AyahNumber],
            notes: [QuranAnnotations.Note]
        ) {
            self.sourceView = sourceView
            self.pointInView = pointInView
            self.verses = verses
            self.notes = notes
        }
    #endif

    // MARK: Internal

    let sourceView: UIView
    let pointInView: CGPoint
    let verses: [AyahNumber]
    #if QURAN_SYNC
        let noteCount: Int
        let highlightVerses: [AyahNumber: HighlightColor]
        let highlightCollections: [AyahBookmarkCollection]
    #else
        let notes: [QuranAnnotations.Note]
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
        #if QURAN_SYNC
            let deps = AyahMenuViewModel.Deps(
                sourceView: input.sourceView,
                pointInView: input.pointInView,
                verses: input.verses,
                textRetriever: textRetriever,
                highlightVerses: input.highlightVerses,
                highlightCollections: input.highlightCollections,
                noteCount: input.noteCount,
                ayahBookmarkCollectionService: AyahBookmarkCollectionService(quranDataService: container.quranDataService)
            )
        #else
            let deps = AyahMenuViewModel.Deps(
                sourceView: input.sourceView,
                pointInView: input.pointInView,
                verses: input.verses,
                textRetriever: textRetriever,
                notes: input.notes,
                noteService: container.noteService()
            )
        #endif
        let viewModel = AyahMenuViewModel(deps: deps)
        viewModel.listener = listener
        return AyahMenuViewController(viewModel: viewModel)
    }

    // MARK: Private

    private let container: AppDependencies
}
