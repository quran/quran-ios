//
//  NoteEditorBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import Foundation
import QuranAnnotations
import QuranKit
import UIKit

@MainActor
public struct NoteEditorBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    #if QURAN_SYNC
    public func build(withListener listener: NoteEditorListener, mode: NoteEditorMode) -> UIViewController {
        let viewModel = NoteEditorViewModel(
            noteService: container.mobileSyncNoteService(),
            analytics: container.analytics,
            mode: mode,
            textForVerses: textForVerses
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #else
    public func build(withListener listener: NoteEditorListener, note: Note) -> UIViewController {
        let viewModel = NoteEditorViewModel(
            noteService: container.noteService(),
            note: note,
            textForVerses: textForVerses
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #endif

    // MARK: Internal

    let container: AppDependencies

    private var textForVerses: ([AyahNumber]) async throws -> String {
        let service = container.noteVerseTextService()
        return service.textForVerses
    }
}
