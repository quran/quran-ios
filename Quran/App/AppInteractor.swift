//
//  AppInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol AppRouting: LaunchRouting {
}

protocol AppPresentable: Presentable {
    var listener: AppPresentableListener? { get set }
}

final class AppInteractor: PresentableInteractor<AppPresentable>, AppInteractable, AppPresentableListener {

    weak var router: AppRouting?

    // TODO: Add additional dependencies to constructor. Do not perform any logic
    // in constructor.
    override init(presenter: AppPresentable) {
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
