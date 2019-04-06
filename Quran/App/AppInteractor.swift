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

    override init(presenter: AppPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }
}
