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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let container: Container

    override init() {
        // initialize craslytics
        Fabric.with([Crashlytics.self, Answers.self])

        // mandatory to be at the top
        Crash.crasher = CrashlyticsCrasher()
        DispatchQueue.default = .global()

        // create the dependency injection container
        container = Container()
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        themeDidChange()

        window.rootViewController = container.createRootViewController()
        window.makeKeyAndVisible()

        container.createReviewService().checkForReview()

        return true
    }

    @objc
    private func themeDidChange() {
        // window
        window?.tintColor = .buttonsTint

        // search bar
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [
            NSAttributedStringKey.foregroundColor.rawValue: UIColor.white,
            NSAttributedStringKey.font.rawValue: UIFont.systemFont(ofSize: 14)
        ]
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let downloadManager = container.createDownloadManager()
        downloadManager.backgroundSessionCompletionHandler = completionHandler
    }
}
