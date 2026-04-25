//
//  NotesTab.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import Localization
import NotesFeature
import QuranViewFeature
import UIKit

struct NotesTabBuilder: TabBuildable {
    let container: AppDependencies

    func build() -> UIViewController {
        let notesBuilder = NotesBuilder(container: container)

        #if QURAN_SYNC
            let interactor: NotesTabInteractor = if container.notesSyncService != nil, container.syncService != nil {
                NotesTabInteractor(
                    quranBuilder: QuranBuilder(container: container),
                    notesBuilder: notesBuilder,
                    syncedNotesBuilder: SyncedNotesBuilder(container: container)
                )
            } else {
                NotesTabInteractor(
                    quranBuilder: QuranBuilder(container: container),
                    notesBuilder: notesBuilder,
                    syncedNotesBuilder: nil
                )
            }
        #else
            let interactor = NotesTabInteractor(
                quranBuilder: QuranBuilder(container: container),
                notesBuilder: notesBuilder
            )
        #endif

        let viewController = NotesTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class NotesTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(
        quranBuilder: QuranBuilder,
        notesBuilder: NotesBuilder
    ) {
        self.notesBuilder = notesBuilder
        #if QURAN_SYNC
            syncedNotesBuilder = nil
        #endif
        super.init(quranBuilder: quranBuilder)
    }

    #if QURAN_SYNC
        init(
            quranBuilder: QuranBuilder,
            notesBuilder: NotesBuilder,
            syncedNotesBuilder: SyncedNotesBuilder?
        ) {
            self.syncedNotesBuilder = syncedNotesBuilder
            self.notesBuilder = notesBuilder
            super.init(quranBuilder: quranBuilder)
        }
    #endif

    // MARK: Internal

    override func start() {
        #if QURAN_SYNC
            let rootViewController: UIViewController = if let syncedNotesBuilder {
                syncedNotesBuilder.build(withListener: self)
            } else {
                notesBuilder.build(withListener: self)
            }
        #else
            let rootViewController = notesBuilder.build(withListener: self)
        #endif

        presenter?.setViewControllers([rootViewController], animated: false)
    }

    // MARK: Private

    private let notesBuilder: NotesBuilder
    #if QURAN_SYNC
        private let syncedNotesBuilder: SyncedNotesBuilder?
    #endif
}

private class NotesTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: l("tab.notes"),
            image: .symbol("text.badge.star"),
            selectedImage: .symbol("text.badge.star", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        )
    }
}
