//
//  AppDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/18/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let container = Container()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self, Answers.self])

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        configureAppAppearance()

        window.rootViewController = container.createRootViewController()
        window.makeKeyAndVisible()
        return true
    }

    fileprivate func configureAppAppearance() {
        window?.tintColor = UIColor.appIdentity()
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor.appIdentity()
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let downloadManager = container.createDownloadManager()
        downloadManager.backgroundSessionCompletionHandler = completionHandler
    }
}
