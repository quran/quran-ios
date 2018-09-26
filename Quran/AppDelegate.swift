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
    private let updateHandler = UpdateHandler()

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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
            print("Document path:", FileManager.documentsPath)
        #endif

        Analytics.shared.logSystemLanguage()

        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        themeDidChange()

        window.rootViewController = container.createRootViewController()
        window.makeKeyAndVisible()

        container.createReviewService().checkForReview()

        versionUpdate()

        return true
    }

    private func versionUpdate() {
        updateHandler.add(updater: DarkThemeUpdater(persistence: container.createSimplePersistence()), for: "1.8.0")
        let updater = AppUpdater()
        let versionUpdate = updater.updated()
        CLog("Version Update:", versionUpdate)
        updateHandler.onUpdate(versionUpdate: versionUpdate)
    }

    @objc
    private func themeDidChange() {
        // window
        window?.tintColor = .buttonsTint

        // search bar
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white,
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)
        ]
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        let downloadManager = container.createDownloadManager()
        downloadManager.backgroundSessionCompletionHandler = completionHandler
    }
}
