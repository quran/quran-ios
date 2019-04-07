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
}
