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
    // TODO: Declare methods the interactor can invoke to manage sub-tree via the router.
}

protocol JuzsPresentable: Presentable {
    var listener: JuzsPresentableListener? { get set }
    // TODO: Declare methods the interactor can invoke the presenter to present data.
}

protocol JuzsListener: class {
    // TODO: Declare methods the interactor can invoke to communicate with other RIBs.
}

final class JuzsInteractor: PresentableInteractor<JuzsPresentable>, JuzsInteractable, JuzsPresentableListener {

    weak var router: JuzsRouting?
    weak var listener: JuzsListener?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: JuzsPresentable) {
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
}
