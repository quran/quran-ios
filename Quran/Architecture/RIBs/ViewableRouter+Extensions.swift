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
        guard let presentedController = viewControllable.uiviewController.presentedViewController else {
            fatalError("No controller presented to dismiss")
        }
        guard let child = getChildRouterForPresentedController(presentedController) else {
            fatalError("Cannot find child router for presented controller '\(presentedController)'")
        }
        viewControllable.dismiss(animated: animated) {
            self.detachChild(child)
            completion?()
        }
    }

    private func getChildRouterForPresentedController(_ presentedController: UIViewController) -> ViewableRouting? {
        // search children controller since we could change hierarchy with viewControllerForAdaptivePresentationStyle
        for controller in [presentedController] + presentedController.children {
            for child in children {
                if let viewableChild = child as? ViewableRouting {
                    if viewableChild.viewControllable.uiviewController === controller {
                        return viewableChild
                    }
                }
            }
        }
        return nil
    }
}
