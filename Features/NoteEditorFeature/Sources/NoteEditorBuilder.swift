//
//  NoteEditorBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 12/20/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
#if QURAN_SYNC
import FeaturesSupport
#endif
import Foundation
import NoorUI
import QuranAnnotations
import QuranKit
import QuranTextKit
import UIKit

@MainActor
public struct NoteEditorBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    #if QURAN_SYNC
    /// `bottomBarsHeight` keeps the sign-in toast above the bottom bars of the screen under the editor.
    public func build(
        withListener listener: NoteEditorListener,
        mode: NoteEditorMode,
        bottomBarsHeight: @escaping @MainActor () -> CGFloat
    ) -> UIViewController {
        weak var editor: UIViewController?
        let signInNudge = SyncSignInNudge(
            authenticationClient: container.authenticationClient,
            analytics: container.analytics,
            // The editor closes after saving, so Sign In falls back to the screens under it.
            signInViewControllers: {
                editor.map { Array(sequence(first: $0, next: \.presentingViewController)) } ?? []
            }
        )
        let viewModel = NoteEditorViewModel(
            noteService: container.mobileSyncNoteService(),
            analytics: container.analytics,
            mode: mode,
            textService: container.textDataService(),
            signInNudge: signInNudge,
            showToast: { toast in
                guard let view = editor?.viewIfLoaded else {
                    return
                }
                ToastPresenter.shared.showToast(toast, from: view, bottomBarsHeight: bottomBarsHeight())
            }
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        editor = viewController
        viewModel.listener = listener
        return viewController
    }
    #else
    public func build(withListener listener: NoteEditorListener, note: Note) -> UIViewController {
        let viewModel = NoteEditorViewModel(
            noteService: container.noteService(),
            note: note,
            textService: container.textDataService()
        )
        let viewController = NoteEditorViewController(viewModel: viewModel)
        viewModel.listener = listener
        return viewController
    }
    #endif

    // MARK: Internal

    let container: AppDependencies
}
