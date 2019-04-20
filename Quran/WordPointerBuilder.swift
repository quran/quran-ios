//
//  WordPointerBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/13/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

protocol WordPointerBuildable: Buildable {
    func build(withListener listener: WordPointerListener,
               hideWordPointerStream: HideWordPointerStream,
               showWordPointerStream: ShowWordPointerStream) -> WordPointerRouting
}

final class WordPointerBuilder: Builder, WordPointerBuildable {

    func build(withListener listener: WordPointerListener,
               hideWordPointerStream: HideWordPointerStream,
               showWordPointerStream: ShowWordPointerStream) -> WordPointerRouting {
        let viewController = WordPointerViewController()
        let interactor = WordPointerInteractor(presenter: viewController, deps: WordPointerInteractor.Deps(
            simplePersistence: container.createSimplePersistence(),
            wordByWordPersistence: SQLiteArabicTextPersistence(),
            hideWordPointerStream: hideWordPointerStream,
            showWordPointerStream: showWordPointerStream))
        interactor.listener = listener
        return WordPointerRouter(interactor: interactor,
                                 viewController: viewController,
                                 translationTextTypeSelectionBuilder: TranslationTextTypeSelectionBuilder(container: container))
    }
}
