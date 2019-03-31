//
//  NavigationRouter+Pop.swift
//  Fresh List
//
//  Created by Mohamed Afifi on 1/5/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import RIBs
import UIKit

extension NavigationRouter: NavigationControllerPopMonitorDelegate {
    public func viewControllerDidPop(_ controller: UIViewController) {
        if let child = children.first(where: { router in
            if let viewableRouter = router as? ViewableRouting {
                return viewableRouter.viewControllable.uiviewController === controller
            }
            return false
        }) {
            detachChild(child)
        }
    }
}
