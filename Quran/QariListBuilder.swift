//
//  QariListBuilder.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/6/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs

// MARK: - Builder

protocol QariListBuildable: Buildable {
    func build(withListener listener: QariListListener) -> QariListRouting
}

final class QariListBuilder: Builder, QariListBuildable {

    func build(withListener listener: QariListListener) -> QariListRouting {
        let viewController = QariTableViewController()
        let interactor = QariListInteractor(presenter: viewController, deps: QariListInteractor.Deps(
            qariRetreiver: container.createQarisDataRetriever(),
            persistence: container.createSimplePersistence()
        ))
        interactor.listener = listener
        return QariListRouter(interactor: interactor, viewController: viewController)
    }
}
