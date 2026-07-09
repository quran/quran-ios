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
    public func build(withListener listener: NoteEditorListener, note: Note) -> UIViewController {
        build(withListener: listener, mode: .edit(note))
    }

    public func build(withListener listener: NoteEditorListener, verses: [AyahNumber]) -> UIViewController {
        build(withListener: listener, mode: .create(verses: verses))
    }
    #else
    public func build(withListener listener: NoteEditorListener, note: Note) -> UIViewController {
        let viewModel = NoteEditorViewModel(noteService: container.noteService(), note: note)
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #endif

    // MARK: Internal

    let container: AppDependencies

    #if QURAN_SYNC
    private func build(withListener listener: NoteEditorListener, mode: NoteEditorViewModel.Mode) -> UIViewController {
        let textService = container.textDataService()
        let viewModel = NoteEditorViewModel(
            noteService: container.mobileSyncNoteService(),
            analytics: container.analytics,
            mode: mode,
            textForVerses: { verses in
                let verseTexts = try await textService.textForVerses(verses, translations: [])
                return verses.sorted()
                    .compactMap { verse in
                        verseTexts[verse].map { $0.arabicText + " \(NumberFormatter.arabicNumberFormatter.format(verse.ayah))" }
                    }
                    .joined(separator: " ")
            }
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #endif
}
