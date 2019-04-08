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

    func setSuras(_ surasArray: [JuzSuras])
}

protocol SurasListener: class {
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

final class SurasInteractor: PresentableInteractor<SurasPresentable>, SurasInteractable, SurasPresentableListener {

    weak var router: SurasRouting?
    weak var listener: SurasListener?

    private let surasRetriever: SurasDataRetrieverType

    init(presenter: SurasPresentable, surasRetriever: SurasDataRetrieverType) {
        self.surasRetriever = surasRetriever
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        surasRetriever
            .getSuras()
            .done(on: .main) { [weak self] suras in
                self?.presenter.setSuras(suras)
            }
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        Analytics.shared.openingQuran(from: .suras)
        listener?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
