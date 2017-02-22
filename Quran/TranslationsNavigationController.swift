//
//  TranslationsNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 2/22/17.
//  Copyright © 2017 Quran.com. All rights reserved.
//

import UIKit

class TranslationsNavigationController: BaseNavigationController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        tabBarItem = UITabBarItem(title: NSLocalizedString("prefs_translations", tableName: "Android", comment: ""),
                                  image: UIImage(named: "globe-25"),
                                  selectedImage: UIImage(named: "globe_filled-25"))
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }
}
