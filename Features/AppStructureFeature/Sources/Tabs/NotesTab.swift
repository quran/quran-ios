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
    let showBookmarks: () -> Void

    func build() -> UIViewController {
        let interactor = NotesTabInteractor(
            quranBuilder: QuranBuilder(container: container),
            notesBuilder: NotesBuilder(container: container),
            showBookmarks: showBookmarks
        )
        let viewController = NotesTabViewController(interactor: interactor)
        viewController.navigationBar.prefersLargeTitles = true
        return viewController
    }
}

private final class NotesTabInteractor: TabInteractor {
    // MARK: Lifecycle

    init(quranBuilder: QuranBuilder, notesBuilder: NotesBuilder, showBookmarks: @escaping () -> Void) {
        self.notesBuilder = notesBuilder
        self.showBookmarks = showBookmarks
        super.init(quranBuilder: quranBuilder)
    }

    // MARK: Internal

    override func start() {
        let rootViewController = notesBuilder.build(withListener: self, showHighlights: showBookmarks)
        presenter?.setViewControllers([rootViewController], animated: false)
    }

    // MARK: Private

    private let notesBuilder: NotesBuilder
    private let showBookmarks: () -> Void
}

private class NotesTabViewController: TabViewController {
    override func getTabBarItem() -> UITabBarItem {
        UITabBarItem(
            title: l("tab.notes"),
            image: .symbol("text.justify.leading"),
            selectedImage: .symbol("text.justify.leading", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        )
    }
}
