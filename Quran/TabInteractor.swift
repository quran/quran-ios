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
}

protocol TabListener: class {
}

class TabInteractor: PresentableInteractor<TabPresentable>, TabInteractable, TabPresentableListener {

    weak var router: TabRouting?
    weak var listener: TabListener?

    override init(presenter: TabPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber) {
        router?.navigateTo(quranPage: quranPage, highlightingAyah: highlightingAyah)
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        router?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
