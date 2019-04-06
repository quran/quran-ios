//
//  SettingsInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol SettingsRouting: ViewableRouting {
}

protocol SettingsPresentable: Presentable {
    var listener: SettingsPresentableListener? { get set }
}

protocol SettingsListener: class {
}

final class SettingsInteractor: PresentableInteractor<SettingsPresentable>, SettingsInteractable, SettingsPresentableListener {

    weak var router: SettingsRouting?
    weak var listener: SettingsListener?

    override init(presenter: SettingsPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }
}
