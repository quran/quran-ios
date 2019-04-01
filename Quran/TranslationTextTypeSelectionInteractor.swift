//
//  TranslationTextTypeSelectionInteractor.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift

protocol TranslationTextTypeSelectionRouting: ViewableRouting {
}

protocol TranslationTextTypeSelectionPresentable: Presentable {
    var listener: TranslationTextTypeSelectionPresentableListener? { get set }

    func setSelectedIndex(selectedIndex: Int?, items: [String])
}

protocol TranslationTextTypeSelectionListener: class {
    func dismissTranslationTextTypeSelection()
}

final class TranslationTextTypeSelectionInteractor: PresentableInteractor<TranslationTextTypeSelectionPresentable>,
                TranslationTextTypeSelectionInteractable, TranslationTextTypeSelectionPresentableListener {

    weak var router: TranslationTextTypeSelectionRouting?
    weak var listener: TranslationTextTypeSelectionListener?
    private let simplePersistence: SimplePersistence

    init(presenter: TranslationTextTypeSelectionPresentable, simplePersistence: SimplePersistence) {
        self.simplePersistence = simplePersistence
        super.init(presenter: presenter)
        presenter.listener = self
    }

    override func didBecomeActive() {
        super.didBecomeActive()
        let selectedIndex = simplePersistence.valueForKey(.wordTranslationType)
        let items = [l("translationTextType"), l("transliterationTextType")]
        presenter.setSelectedIndex(selectedIndex: selectedIndex, items: items)
    }

    func onItemTapped(at index: Int) {
        simplePersistence.setValue(index, forKey: .wordTranslationType)
        listener?.dismissTranslationTextTypeSelection()
    }
}
