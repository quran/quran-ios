#if QURAN_SYNC
//
//  AyahNotesBuilder.swift
//

import AppDependencies
import NoorUI
import NoteEditorFeature
import QuranKit
import UIKit

@MainActor
public struct AyahNotesBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies, quranFontSource: QuranFontSource) {
        self.container = container
        self.quranFontSource = quranFontSource
    }

    // MARK: Public

    public func build(verses: [AyahNumber], presentsNewNote: Bool = false) -> UIViewController {
        let viewControllerReference = AyahNotesViewControllerReference()
        let viewModel = AyahNotesViewModel(
            verses: verses,
            noteService: container.mobileSyncNoteService()
        )
        let viewController = AyahNotesViewController(
            viewModel: viewModel,
            noteEditorBuilder: .init(container: container, quranFontSource: quranFontSource),
            presentsNewNote: presentsNewNote,
            addAction: { [viewControllerReference] in
                viewControllerReference.value?.addNote()
            },
            editAction: { [viewControllerReference] note in
                viewControllerReference.value?.editNote(note)
            }
        )
        viewControllerReference.value = viewController

        let navigationController = BaseNavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        return navigationController
    }

    // MARK: Private

    private let container: AppDependencies
    private let quranFontSource: QuranFontSource
}

@MainActor
private final class AyahNotesViewControllerReference {
    weak var value: AyahNotesViewController?
}
#endif
