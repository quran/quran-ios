//
//  TranslationTextTypeSelectionBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/31/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol TranslationTextTypeSelectionBuildable: Buildable {
    func build(withListener listener: TranslationTextTypeSelectionListener) -> TranslationTextTypeSelectionRouting
}

final class TranslationTextTypeSelectionBuilder: Builder, TranslationTextTypeSelectionBuildable {

    func build(withListener listener: TranslationTextTypeSelectionListener) -> TranslationTextTypeSelectionRouting {
        let viewController = TranslationTextTypeSelectionTableViewController()
        let interactor = TranslationTextTypeSelectionInteractor(presenter: viewController, simplePersistence: container.createSimplePersistence())
        interactor.listener = listener
        return TranslationTextTypeSelectionRouter(interactor: interactor, viewController: viewController)
    }
}
