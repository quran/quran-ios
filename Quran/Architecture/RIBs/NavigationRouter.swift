//
//  NavigationRouter.swift
//  Fresh List
//
//  Created by Mohamed Afifi on 1/5/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import RIBs

public protocol NavigationRouting: ViewableRouting {
    func setRouters(_ routers: [ViewableRouting], animated: Bool)
    func push(_ router: ViewableRouting, animated: Bool)
    func pop(animated: Bool) -> Bool
    func pop(to router: ViewableRouting, animated: Bool) -> Bool
    func popToRoot(animated: Bool) -> Bool
}

open class NavigationRouter<InteractorType, NavigationControllerType>: ViewableRouter<InteractorType, NavigationControllerType>, NavigationRouting {

    private let navigationControllable: NavigationControllable
    private let popMonitor = NavigationControllerPopMonitor()

    public override init(interactor: InteractorType, viewController: NavigationControllerType) {
        guard let navigationControllable = viewController as? NavigationControllable else {
            fatalError("\(viewController) should conform to \(NavigationControllable.self)")
        }
        self.navigationControllable = navigationControllable
        super.init(interactor: interactor, viewController: viewController)
        popMonitor.delegate = self
        navigationControllable.uinavigationController.delegate = popMonitor
    }

    open func setRouters(_ routers: [ViewableRouting], animated: Bool) {
        routers.forEach { router in attachChild(router) }
        navigationControllable.setViewControllers(routers.map { $0.viewControllable }, animated: animated)
    }

    open func push(_ router: ViewableRouting, animated: Bool) {
        attachChild(router)
        navigationControllable.push(router.viewControllable, animated: animated)
    }

    open func pop(animated: Bool) -> Bool {
        return navigationControllable.pop(animated: animated)
    }

    open func pop(to router: ViewableRouting, animated: Bool) -> Bool {
        return navigationControllable.pop(to: router.viewControllable, animated: animated)
    }

    open func popToRoot(animated: Bool) -> Bool {
        return navigationControllable.popToRoot(animated: animated)
    }
}
