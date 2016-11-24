//
//  JuzsNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class JuzsNavigationController: BaseNavigationController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        tabBarItem = UITabBarItem(title: NSLocalizedString("quran_juz2", tableName: "Android", comment: ""),
                                  image: UIImage(named: "pie_chart-empty-25"),
                                  selectedImage: UIImage(named: "pie_chart-filled-25"))
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }
}
