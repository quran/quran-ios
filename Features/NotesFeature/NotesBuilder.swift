//
//  NotesBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 11/14/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AnnotationsService
import AppDependencies
import FeaturesSupport
import QuranKit
import QuranTextKit
import UIKit

@MainActor
public struct NotesBuilder {
    // MARK: Lifecycle

    public init(container: AppDependencies) {
        self.container = container
    }

    // MARK: Public

    public func build(withListener listener: QuranNavigator) -> UIViewController {
        let pageBookmarkService = PageBookmarkService(persistence: container.pageBookmarkPersistence)
        let interactorDeps = NotesInteractor.Deps(
            analytics: container.analytics,
            noteService: container.noteService(),
            pageBookmarkService: pageBookmarkService
        )
        let interactor = NotesInteractor(deps: interactorDeps)
        interactor.listener = listener
        let viewController = NotesViewController(interactor: interactor)
        return viewController
    }

    // MARK: Internal

    let container: AppDependencies
}
