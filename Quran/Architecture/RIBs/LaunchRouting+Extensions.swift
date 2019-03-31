//
//  LaunchRouting+Extensions.swift
//  Fresh List
//
//  Created by Mohamed Afifi on 1/8/19.
//  Copyright © 2019 Varaw. All rights reserved.
//
import RIBs

public extension LaunchRouting {
    func launchFromWindow(_ window: UIWindow) {
        window.rootViewController = viewControllable.uiviewController
        window.makeKeyAndVisible()

        interactable.activate()
        load()
    }
}
