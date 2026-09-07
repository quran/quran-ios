//
//  TabViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import FeaturesSupport
import NoorUI
import UIKit

class TabViewController: BaseNavigationController, TabPresenter {
    // MARK: Lifecycle

    init(interactor: TabInteractor) {
        self.interactor = interactor
        super.init(nibName: nil, bundle: nil)
        tabBarItem = getTabBarItem()

        interactor.presenter = self
        interactor.start()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not implemented")
    }

    // MARK: Internal

    var quranNavigator: QuranNavigator { interactor }

    func getTabBarItem() -> UITabBarItem {
        fatalError("\(#function) should be subclassed")
    }

    // MARK: Private

    private let interactor: TabInteractor
}
