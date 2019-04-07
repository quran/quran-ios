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
    func setTheme(_ theme: Theme)
    func presentShareApp()
    func presentContactUs()
}

protocol SettingsListener: class {
    func presentTranslationsList()
    func presentAudioDownloads()
}

final class SettingsInteractor: PresentableInteractor<SettingsPresentable>, SettingsInteractable, SettingsPresentableListener {
    struct Deps {
        var persistence: SimplePersistence
    }

    weak var router: SettingsRouting?
    weak var listener: SettingsListener?

    private let application: UIApplication
    private var deps: Deps

    init(presenter: SettingsPresentable, application: UIApplication, deps: Deps) {
        self.application = application
        self.deps = deps
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func viewWillAppear() {
        presenter.setTheme(deps.persistence.theme)
    }

    func onThemeUpdated(to newTheme: Theme) {
        deps.persistence.theme = newTheme
    }

    func onTranslationsTapped() {
        listener?.presentTranslationsList()
    }

    func onAudioDownloadsTapped() {
        listener?.presentAudioDownloads()
    }

    func onShareAppTapped() {
        presenter.presentShareApp()
        Analytics.shared.shareApp()
    }

    func onReviewAppTapped() {
        let url = unwrap(URL(string: "itms-apps://itunes.apple.com/app/id1118663303?action=write-review"))
        if #available(iOS 10.0, *) {
            application.open(url)
        } else {
            application.openURL(url)
        }
        Analytics.shared.review(automatic: false)
    }

    func onContactUsTapped() {
        presenter.presentContactUs()
    }
}
