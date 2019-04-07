//
//  TranslationsListInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol TranslationsListRouting: ViewableRouting {
}

protocol TranslationsListPresentable: Presentable {
    var listener: TranslationsListPresentableListener? { get set }
}

protocol TranslationsListListener: class {
}

final class TranslationsListInteractor: PresentableInteractor<TranslationsListPresentable>,
                    TranslationsListInteractable, TranslationsListPresentableListener {

    weak var router: TranslationsListRouting?
    weak var listener: TranslationsListListener?

    override init(presenter: TranslationsListPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }
}
