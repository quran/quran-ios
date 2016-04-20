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
        let controller = UITabBarController()
        controller.viewControllers = [createSurasController(),
                                      createJuzsController(),
                                      createSearchController(),
                                      createSettingsController()]
//        controller.selectedIndex = 0
        return controller
    }

    func createSurasController() -> UIViewController {
        return SurasNavigationController(rootViewController: SurasViewController())
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
}
