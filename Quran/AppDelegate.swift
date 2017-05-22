//
//  AppDelegate.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/18/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
import Crashlytics
import Fabric
import PromiseKit
import UIKit
import DhtKeychain
import DhtStoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let container: Container

    class func shareInstance() -> AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate ?? nil
    }

    override init() {
        // initialize craslytics
        Fabric.with([Crashlytics.self, Answers.self])

        // mandatory to be at the top
        Crash.crasher = CrashlyticsCrasher()
        DispatchQueue.default = .global()

        // create the dependency injection container
        container = Container()
        super.init()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            print("Document path:", FileManager.documentsPath)
        #endif

        Analytics.shared.logSystemLanguage()

        let updater = AppUpdater()
        let versionUpdate = updater.updated()
        CLog("Version Update:", versionUpdate)

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

    // MARK: Config IAP

    func didPurchaseSuccess(productId: String) {
        Keychains.purchasedid.set(value: productId)
    }

    func hasPurchased() -> Bool {
        return !Keychains.purchasedid.getStringOrEmpty().isEmpty
    }

    func configInAppPurchase() {
        if self.hasPurchased() {
            didPurchaseSuccess(productId: Keychains.purchasedid.getStringOrEmpty())
        } else {
            DhtStoreKit.shared().startProductRequest()
            NotificationCenter.default.addObserver(forName: NSNotification.Name.mkStoreKitProductsAvailable, object: nil, queue: OperationQueue.main) { (note) in
                print(DhtStoreKit.shared().availableProducts)
                let count = DhtStoreKit.shared().availableProducts?.count ?? 0
                if count > 0 {
//                    MKStoreKit.sharedKit().restorePurchases()
                }
            }
        }
    }
}
