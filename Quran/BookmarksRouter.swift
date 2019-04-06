//
//  BookmarksRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol BookmarksInteractable: Interactable {
    var router: BookmarksRouting? { get set }
    var listener: BookmarksListener? { get set }
}

protocol BookmarksViewControllable: ViewControllable {
}

final class BookmarksRouter: ViewableRouter<BookmarksInteractable, BookmarksViewControllable>, BookmarksRouting {

    override init(interactor: BookmarksInteractable, viewController: BookmarksViewControllable) {
        super.init(interactor: interactor, viewController: viewController)
        interactor.router = self
    }
}
