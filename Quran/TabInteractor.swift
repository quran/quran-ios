//
//  TabInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol TabRouting: NavigationRouting {
    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber)
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

protocol TabPresentable: Presentable {
    var listener: TabPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol TabListener: class {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

class TabInteractor: PresentableInteractor<TabPresentable>, TabInteractable, TabPresentableListener {

    weak var router: TabRouting?
    weak var listener: TabListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: TabPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        // TODO: Implement business logic here.
    }

    override func willResignActive() {
        super.willResignActive()
        // TODO: Pause any business logic.
    }

    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber) {
        router?.navigateTo(quranPage: quranPage, highlightingAyah: highlightingAyah)
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        router?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
