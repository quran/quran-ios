#if QURAN_SYNC
//
//  SyncActivityBuilder.swift
//
//
//  Created by Mohamed Afifi on 2026-10-28.
//

import AnnotationsService
import AppDependencies
import Localization
import NoteEditorFeature
import ReadingService
import SwiftUI
import UIKit

@MainActor
struct SyncActivityBuilder {
    let container: AppDependencies

    func build(navigationController: UINavigationController?) -> UIViewController {
        let viewModel = SyncActivityViewModel(
            quranDataService: container.quranDataService,
            editor: heldItemEditor(navigationController: navigationController)
        )
        let viewController = UIHostingController(rootView: SyncActivityView(viewModel: viewModel))
        viewController.title = l("sync.activity.title")
        return viewController
    }

    func heldItemEditor(navigationController: UINavigationController?) -> HeldItemEditor {
        HeldItemEditor(
            noteService: container.mobileSyncNoteService(),
            collectionService: container.ayahBookmarkCollectionService(),
            readingBookmarkService: container.readingBookmarkService(),
            readingPreferences: .shared,
            noteEditorBuilder: NoteEditorBuilder(container: container),
            navigationController: navigationController
        )
    }
}
#endif
