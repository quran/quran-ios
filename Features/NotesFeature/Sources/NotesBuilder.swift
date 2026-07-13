//
//  NotesBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import FeaturesSupport
import NoteEditorFeature
import QuranAnnotations
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
        let viewControllerReference = NotesViewControllerReference()
        let editNote: (Note) -> Void = { [viewControllerReference] note in
            viewControllerReference.value?.editNote(note)
        }
        let textService = container.textDataService()
        let textRetriever = ShareableVerseTextRetriever(
            databasesURL: container.databasesURL,
            quranFileURL: container.quranUthmaniV2Database
        )

        #if QURAN_SYNC
        let noteService = container.mobileSyncNoteService()
        let viewModel = NotesViewModel(
            noteService: noteService,
            textService: textService,
            textRetriever: textRetriever,
            navigateTo: { [weak listener] verse in
                listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: nil)
            },
            editNote: editNote
        )
        #else
        let viewModel = NotesViewModel(
            analytics: container.analytics,
            noteService: container.noteService(),
            textRetriever: textRetriever,
            textService: textService,
            navigateTo: { [weak listener] verse in
                listener?.navigateTo(page: verse.page, lastPage: nil, highlightingSearchAyah: nil)
            },
            editNote: editNote
        )
        #endif

        let viewController = NotesViewController(
            viewModel: viewModel,
            noteEditorBuilder: NoteEditorBuilder(container: container)
        )
        viewControllerReference.value = viewController
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}

@MainActor
private final class NotesViewControllerReference {
    weak var value: NotesViewController?
}
