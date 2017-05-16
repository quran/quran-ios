//
//  SearchBuilder.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/15/17.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

protocol SearchBuilder: class {
    func build() -> (SearchRouter, UIViewController) // DESIGN: should remove UIViewController
}

class DefaultSearchBuilder: SearchBuilder {

    let container: Container // DESIGN: shouldn't be here
    init(container: Container) {
        self.container = container
    }

    func build() -> (SearchRouter, UIViewController) {
        let view = SearchViewController()
        let navigation = SearchNavigationController() // DESIGN: shouldn't be created here
        navigation.viewControllers = [view]

        let interactor = DefaultSearchInteractor()
        let presenter = DefaultSearchPresenter()

        let router: SearchRouter = NavigationSearchRouter(
            interactor: interactor,
            presenter: presenter,
            navigationController: navigation,
            quranControllerCreator: AnyCreator(createClosure: container.createQuranController)) // DESIGN: should be quran router

        view.delegate = presenter

        presenter.interactor = interactor
        presenter.view = view

        interactor.presenter = presenter
        interactor.router = router

        view.router = router // DESIGN: Shouldn't be saved here

        return (router, navigation)
    }
}
