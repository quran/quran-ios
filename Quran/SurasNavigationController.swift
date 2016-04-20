//
//  SurasNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class SurasNavigationController: BaseNavigationController {

    override var tabBarItem: UITabBarItem! {
        get {
            return UITabBarItem(title: "Suras", image: UIImage(named: "first"), selectedImage: nil)
        }
        set {
            super.tabBarItem = newValue
        }
    }
}
