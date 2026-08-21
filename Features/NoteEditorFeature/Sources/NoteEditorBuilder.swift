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
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

@MainActor
public struct NoteEditorBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, quranFontSource: QuranFontSource) {
        self.container = container
        self.quranFontSource = quranFontSource
    }

    // MARK: Public

    #if QURAN_SYNC
    public func build(withListener listener: NoteEditorListener, mode: NoteEditorMode) -> UIViewController {
        let viewModel = NoteEditorViewModel(
            noteService: container.mobileSyncNoteService(),
            analytics: container.analytics,
            mode: mode,
            textService: container.textDataService(),
            quranFontSource: quranFontSource
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
            textService: container.textDataService(),
            quranFontSource: quranFontSource
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #endif

    // MARK: Internal

    let container: AppDependencies
    let quranFontSource: QuranFontSource
}
