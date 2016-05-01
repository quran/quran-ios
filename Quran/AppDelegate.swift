//
//  AppDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/18/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let container = Container()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window = window
        configureAppAppearance()

        window.rootViewController = container.createRootViewController()
        window.makeKeyAndVisible()
        return true
    }

    private func configureAppAppearance() {
        window?.tintColor = UIColor.appIdentity()
        UINavigationBar.appearance().tintColor = UIColor.whiteColor()
        UINavigationBar.appearance().barTintColor = UIColor.appIdentity()
    }
}
