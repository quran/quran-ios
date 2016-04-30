//
//  Container.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/20/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class Container {

    // service registery
    static var defaultContainer: Container = Container()

    func createRootViewController() -> UIViewController {
        let controller = MainTabBarController()
        controller.viewControllers = [createSurasController(),
                                      createJuzsController(),
                                      createSettingsController()]
        return controller
    }

    func createSurasController() -> UIViewController {
        return SurasNavigationController(rootViewController: SurasViewController(dataRetriever: createSurasRetriever()))
    }

    func createJuzsController() -> UIViewController {
        return JuzsNavigationController(rootViewController: JuzsViewController())
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
}
