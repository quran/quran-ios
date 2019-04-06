//
//  SurasInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol SurasRouting: ViewableRouting {
}

protocol SurasPresentable: Presentable {
    var listener: SurasPresentableListener? { get set }
}

protocol SurasListener: class {
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

final class SurasInteractor: PresentableInteractor<SurasPresentable>, SurasInteractable, SurasPresentableListener {

    weak var router: SurasRouting?
    weak var listener: SurasListener?

    override init(presenter: SurasPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        Analytics.shared.openingQuran(from: .suras)
        listener?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
