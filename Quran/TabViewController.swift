//
//  TabViewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 3/24/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//

import RIBs
import RxSwift
import UIKit

protocol TabPresentableListener: class {

}

class TabViewController: BaseNavigationController, TabPresentable, TabViewControllable {

    weak var listener: TabPresentableListener?

    init() {
        super.init(nibName: nil, bundle: nil)
        tabBarItem = getTabBarItem()
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        tabBarItem = getTabBarItem()
    }

    required init?(coder aDecoder: NSCoder) {
        unimplemented()
    }

    func getTabBarItem() -> UITabBarItem {
        expectedToBeSubclassed()
    }
}
