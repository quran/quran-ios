//
//  BookmarksNavigationController.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/26/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

class BookmarksNavigationController: BaseNavigationController {

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        tabBarItem = UITabBarItem(title: NSLocalizedString("menu_bookmarks", tableName: "Android", comment: ""),
                                  image: #imageLiteral(resourceName: "bookmarks-empty-25"),
                                  selectedImage: #imageLiteral(resourceName: "bookmarks-filled-25"))
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }
}
