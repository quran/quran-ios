//
//  NotesBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import FeaturesSupport
#if QURAN_SYNC
import NoteEditorFeature
#endif
import QuranKit
import QuranTextKit
import UIKit

@MainActor
public struct NotesBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        #if QURAN_SYNC
        let noteService = container.mobileSyncNoteService()
        let textService = container.textDataService()
        let viewModel = SyncedNotesViewModel(noteService: noteService, textService: textService)
        return SyncedNotesViewController(
            viewModel: viewModel,
            noteEditorBuilder: SyncedNoteEditorBuilder(
                noteService: noteService,
                textService: textService,
                analytics: container.analytics
            )
        )
        #else
        let textRetriever = ShareableVerseTextRetriever(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )

        let viewModel = NotesViewModel(
            analytics: container.analytics,
            noteService: container.noteService(),
            textRetriever: textRetriever,
            navigateTo: { [weak listener] verse in
                listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: nil)
            }
        )
        return NotesViewController(viewModel: viewModel)
        #endif
    }

    // MARK: Internal

    let container: AppDependencies
}
