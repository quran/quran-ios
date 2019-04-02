//
//  MoreMenuInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/1/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

struct MoreMenuModel {
    var mode: QuranMode
    var isWordPointerActive: Bool
    var fontSize: FontSize
    var theme: Theme
}

protocol MoreMenuRouting: ViewableRouting {
}

protocol MoreMenuPresentable: Presentable {
    var listener: MoreMenuPresentableListener? { get set }
}

protocol MoreMenuListener: class {
    func onQuranModeUpdated(to mode: QuranMode)
    func onTranslationsSelectionsTapped()
    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool)
    func onFontSizedUpdated(to fontSize: FontSize)
    func onThemeSelectedUpdated(to theme: Theme)
}

final class MoreMenuInteractor: PresentableInteractor<MoreMenuPresentable>, MoreMenuInteractable, MoreMenuPresentableListener {

    weak var router: MoreMenuRouting?
    weak var listener: MoreMenuListener?

    override init(presenter: MoreMenuPresentable) {
        super.init(presenter: presenter)
        presenter.listener = self
    }

    func onQuranModeUpdated(to mode: QuranMode) {
        listener?.onQuranModeUpdated(to: mode)
    }

    func onTranslationsSelectionsTapped() {
        listener?.onTranslationsSelectionsTapped()
    }

    func onIsWordPointerActiveUpdated(to isWordPointerActive: Bool) {
        listener?.onIsWordPointerActiveUpdated(to: isWordPointerActive)
    }

    func onFontSizedUpdated(to fontSize: FontSize) {
        listener?.onFontSizedUpdated(to: fontSize)
    }

    func onThemeSelectedUpdated(to theme: Theme) {
        listener?.onThemeSelectedUpdated(to: theme)
    }
}
