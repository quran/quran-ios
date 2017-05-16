//
//  SearchRouter.swift
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

protocol SearchRouter: class {
    var interactor: SearchInteractor { get }
    var presenter: SearchPresenter { get }

    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber)
}

class NavigationSearchRouter: SearchRouter {

    private weak var navigationController: UINavigationController?    // DESIGN: Shouldn't be weak
    private let quranControllerCreator: AnyCreator<(Int, LastPage?), QuranViewController>

    let interactor: SearchInteractor
    let presenter: SearchPresenter

    init(interactor: SearchInteractor,
         presenter: SearchPresenter,
         navigationController: UINavigationController?,
         quranControllerCreator: AnyCreator<(Int, LastPage?), QuranViewController>) {
        self.interactor = interactor
        self.presenter = presenter
        self.navigationController = navigationController
        self.quranControllerCreator = quranControllerCreator
    }

    func navigateTo(quranPage: Int, highlightingAyah: AyahNumber) {
        let controller = quranControllerCreator.create((quranPage, nil))
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
}
