//
//  ViewableRouter+Extensions.swift
//  Bday
//
//  Created by Mohamed Afifi on 1/12/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import RIBs

extension ViewableRouter {
    func addFullScreenChild(_ router: ViewableRouting) {
        viewControllable.addFullScreenChild(router.viewControllable)
        attachChild(router)
    }

    func removeFirstChild<T>(ofKind kind: T.Type) {
        guard let router = children.first(where: { $0 is T }) as? ViewableRouting else {
            return
        }
        removeChild(router)
    }

    func removeChild(_ router: ViewableRouting) {
        viewControllable.removeChild(router.viewControllable)
        detachChild(router)
    }

    func present(_ router: ViewableRouting, animated: Bool, completion: (() -> Void)? = nil) {
        viewControllable.present(router.viewControllable, animated: animated, completion: completion)
        attachChild(router)
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        let presentedController = viewControllable.uiviewController.presentedViewController
        if let child = children.first(where: { router in
            if let viewableRouter = router as? ViewableRouting {
                return viewableRouter.viewControllable.uiviewController === presentedController
            }
            return false
        }) as? ViewableRouting {
            viewControllable.dismiss(animated: animated) {
                self.detachChild(child)
                completion?()
            }
        }
    }
}
