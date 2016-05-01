//
//  Container.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class Container {

    func createRootViewController() -> UIViewController {
        let controller = MainTabBarController()
        controller.viewControllers = [createSurasNavigationController(),
                                      createJuzsNavigationController(),
                                      createSettingsController()]
        return controller
    }

    func createSurasNavigationController() -> UIViewController {
        return SurasNavigationController(rootViewController: createSurasViewController())
    }

    func createJuzsNavigationController() -> UIViewController {
        return JuzsNavigationController(rootViewController: createJuzsViewController())
    }

    func createSurasViewController() -> UIViewController {
        return SurasViewController(dataRetriever: createSurasRetriever(), quranControllerCreator: createControllerCreator())
    }

    func createJuzsViewController() -> UIViewController {
        return JuzsViewController(dataRetriever: createQuartersRetriever(), quranControllerCreator: createControllerCreator())
    }

    func createSearchController() -> UIViewController {
        return SearchNavigationController(rootViewController: SearchViewController())
    }

    func createSettingsController() -> UIViewController {
        return SettingsNavigationController(rootViewController: SettingsViewController())
    }

    func createSurasRetriever() -> AnyDataRetriever<[(Juz, [Sura])]> {
        return SurasDataRetriever().erasedType()
    }

    func createQuartersRetriever() -> AnyDataRetriever<[(Juz, [Quarter])]> {
        return QuartersDataRetriever().erasedType()
    }

    func createQuranController() -> QuranViewController {
        return QuranViewController()
    }

    func createControllerCreator<ViewController: UIViewController>() -> AnyCreator<ViewController> {
        return ViewControllersCreator().erasedType()
    }
}
