//
//  NoteEditorBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import AnnotationsService
import AppDependencies
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

#if !QURAN_SYNC
    @MainActor
    public struct NoteEditorBuilder {
        // MARK: Lifecycle

        public init(container: AppDependencies) {
            self.container = container
        }

        // MARK: Public

        public func build(withListener listener: NoteEditorListener, note: Note) -> UIViewController {
            let noteService = container.noteService()
            let viewModel = NoteEditorInteractor(noteService: noteService, note: note)
            let viewController = NoteEditorViewController(viewModel: viewModel)
            viewModel.listener = listener
            return viewController
        }

        // MARK: Internal

        let container: AppDependencies
    }
#endif

#if QURAN_SYNC
    @MainActor
    public struct SyncedNoteEditorBuilder {
        public init(noteService: MobileSyncNoteService, textService: QuranTextDataService, analytics: AnalyticsLibrary) {
            self.noteService = noteService
            self.textService = textService
            self.analytics = analytics
        }

        public func build(withListener listener: NoteEditorListener, note: SyncedNote) -> UIViewController {
            build(withListener: listener, mode: .edit(note))
        }

        public func build(withListener listener: NoteEditorListener, verses: [AyahNumber]) -> UIViewController {
            build(withListener: listener, mode: .create(verses: verses))
        }

        private let noteService: MobileSyncNoteService
        private let textService: QuranTextDataService
        private let analytics: AnalyticsLibrary

        private func build(withListener listener: NoteEditorListener, mode: SyncedNoteEditorInteractor.Mode) -> UIViewController {
            let viewModel = SyncedNoteEditorInteractor(noteService: noteService, textService: textService, analytics: analytics, mode: mode)
            let viewController = SyncedNoteEditorViewController(viewModel: viewModel)
            viewModel.listener = listener
            return viewController
        }
    }
#endif
