//
//  QariListInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol QariListRouting: ViewableRouting {
}

protocol QariListPresentable: Presentable {
    var listener: QariListPresentableListener? { get set }

    func setQaris(_ qaris: [Qari], selectedQariIndex: Int)
}

protocol QariListListener: class {
    func onSelectedQariChanged()
    func dismissQariList()
}

final class QariListInteractor: PresentableInteractor<QariListPresentable>, QariListInteractable, QariListPresentableListener {
    weak var router: QariListRouting?
    weak var listener: QariListListener?

    struct Deps {
        let qariRetreiver: QariDataRetrieverType
        let persistence: SimplePersistence
    }

    private let deps: Deps
    private var qaris: [Qari] = []

    init(presenter: QariListPresentable, deps: Deps) {
        self.deps = deps
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()

        deps.qariRetreiver
            .getQaris()
            .done(on: .main) { qaris in
                self.qaris = qaris
                let lastSelectedQariId = self.deps.persistence.valueForKey(.lastSelectedQariId)
                let selectedQariIndex = qaris.index { $0.id == lastSelectedQariId } ?? qaris[0].id
                self.presenter.setQaris(qaris, selectedQariIndex: selectedQariIndex)
            }
    }

    func onQariItemTapped(at index: Int) {
        let qariId = qaris[index].id
        deps.persistence.setValue(qariId, forKey: .lastSelectedQariId)
        listener?.onSelectedQariChanged()
        listener?.dismissQariList()
    }

    func onCancelButtonTapped() {
        listener?.dismissQariList()
    }
}
