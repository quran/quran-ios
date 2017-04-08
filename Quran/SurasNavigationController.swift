//
//  SurasNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class SurasNavigationController: BaseNavigationController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        tabBarItem = UITabBarItem(title: NSLocalizedString("quran_sura", tableName: "Android", comment: ""),
                                  image: #imageLiteral(resourceName: "page-empty-25"),
                                  selectedImage: #imageLiteral(resourceName: "page-filled-25"))
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }
}
