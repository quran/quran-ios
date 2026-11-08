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

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    /// `bottomBarsHeight` keeps the toast after saving a new note above the presenter's bottom bars.
    public func build(
        verses: [AyahNumber],
        presentsNewNote: Bool = false,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        let viewControllerReference = AyahNotesViewControllerReference()
        let viewModel = AyahNotesViewModel(
            verses: verses,
            noteService: container.mobileSyncNoteService()
        )
        let viewController = AyahNotesViewController(
            viewModel: viewModel,
            noteEditorBuilder: .init(container: container),
            presentsNewNote: presentsNewNote,
            bottomBarsHeight: bottomBarsHeight,
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
}

@MainActor
private final class AyahNotesViewControllerReference {
    weak var value: AyahNotesViewController?
}
#endif
