//
//  PresentingViewableRouter.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/19.
//  Copyright © 2019 Quran.com. All rights reserved.
//
import RIBs

open class PresentingViewableRouter<InteractorType, ViewControllerType>: ViewableRouter<InteractorType, ViewControllerType> {

    private var presentedRouter: ViewableRouting?

    func saveAsPresented(_ router: ViewableRouting) {
        precondition(presentedRouter == nil, "Cannot present '\(router)' on an already presented router '\(unwrap(presentedRouter))'")
        presentedRouter = router
        attachChild(router)
    }

    func present(_ router: ViewableRouting, animated: Bool, completion: (() -> Void)? = nil) {
        saveAsPresented(router)
        viewControllable.present(router.viewControllable, animated: animated, completion: completion)
    }

    func dismiss(animated: Bool, completion userCompletion: (() -> Void)? = nil) {
        guard let dismissingRouter = presentedRouter else {
            fatalError("No router presented to dismiss")
        }
        let completion: (() -> Void) = { [weak self] in
            self?.presentedRouter = nil
            self?.detachChild(dismissingRouter)
            userCompletion?()
        }
        if viewControllable.uiviewController.presentedViewController == nil {
            completion()
        } else {
            viewControllable.dismiss(animated: animated, completion: completion)
        }
    }
}
