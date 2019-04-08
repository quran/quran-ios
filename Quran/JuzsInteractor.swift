//
//  JuzsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol JuzsRouting: ViewableRouting {
}

protocol JuzsPresentable: Presentable {
    var listener: JuzsPresentableListener? { get set }

    func setQuarters(_ quartersArray: [JuzQuarters])
}

protocol JuzsListener: class {
    func navigateTo(quranPage: Int, lastPage: LastPage?)
}

final class JuzsInteractor: PresentableInteractor<JuzsPresentable>, JuzsInteractable, JuzsPresentableListener {

    weak var router: JuzsRouting?
    weak var listener: JuzsListener?

    private let quartersRetriever: QuartersDataRetrieverType

    init(presenter: JuzsPresentable, quartersRetriever: QuartersDataRetriever) {
        self.quartersRetriever = quartersRetriever
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        quartersRetriever
            .getQuarters()
            .done(on: .main) { [weak self] quarters in
                self?.presenter.setQuarters(quarters)
            }
    }

    func navigateTo(quranPage: Int, lastPage: LastPage?) {
        Analytics.shared.openingQuran(from: .juzs)
        listener?.navigateTo(quranPage: quranPage, lastPage: lastPage)
    }
}
