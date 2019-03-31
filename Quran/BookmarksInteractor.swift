//
//  BookmarksInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol BookmarksRouting: ViewableRouting {
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol BookmarksPresentable: Presentable {
    var listener: BookmarksPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol BookmarksListener: class {
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

final class BookmarksInteractor: PresentableInteractor<BookmarksPresentable>, BookmarksInteractable, BookmarksPresentableListener {

    weak var router: BookmarksRouting?
    weak var listener: BookmarksListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: BookmarksPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        Analytics.shared.openingQuran(from: .bookmarks)
        listener?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
