//
//  AppViewController.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/19/16.
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

import Analytics
import Crashing
import UIKit
import VLogging
import WhatsNewFeature

protocol AppPresenter: UITabBarController {
}

class AppViewController: UITabBarController, UITabBarControllerDelegate, AppPresenter {
    // MARK: Lifecycle

    init(analytics: AnalyticsLibrary, interactor: AppInteractor) {
        self.interactor = interactor
        whatsNewController = AppWhatsNewController(analytics: analytics)
        super.init(nibName: nil, bundle: nil)
        interactor.presenter = self
        interactor.start()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Open

    override open var shouldAutorotate: Bool {
        visibleViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        visibleViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        tabBarVisibilityObservation = tabBar.observe(\.isHidden, options: [.initial, .new]) { [weak self] _, _ in
            self?.synchronizeTabBarContainerVisibility()
        }
        updateCrashContext(selectedIndex: selectedIndex)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        synchronizeTabBarContainerVisibility()
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        crashContext.setNavigationPhase("tab_switching")
        updateCrashContext(selectedIndex: tabBarController.selectedIndex)
        crashContext.setNavigationPhase("idle")
        let targetMask = tabBarController.supportedInterfaceOrientations
        if let currentMask = tabBarController.view.window?.windowScene?.interfaceOrientation.asMask {
            if !targetMask.contains(currentMask) {
                if let interface = targetMask.asOrientation {
                    UIDevice.current.setValue(interface.rawValue, forKey: "orientation")
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard !hasStartedPostLaunchPresentation else { return }
        hasStartedPostLaunchPresentation = true

        whatsNewController.presentWhatsNewIfNeeded(from: self)
    }

    // MARK: Private

    private let interactor: AppInteractor
    private let whatsNewController: AppWhatsNewController
    private var hasStartedPostLaunchPresentation = false
    private var tabBarVisibilityObservation: NSKeyValueObservation?

    private let tabNames = ["home", "notes", "bookmarks", "search", "settings"]

    private var visibleViewController: UIViewController? {
        presentedViewController ?? selectedViewController
    }

    private func updateCrashContext(selectedIndex: Int) {
        let tab = tabNames.indices.contains(selectedIndex) ? tabNames[selectedIndex] : "unknown"
        crashContext.setSelectedTab(tab)
        crashContext.setScreen(tab)
        logger.info("Crash context: selected tab \(tab)")
    }
}

extension UITabBarController {
    func synchronizeTabBarContainerVisibility() {
        guard #available(iOS 26.0, *) else { return }
        guard let containerView = tabBar.superview?.superview,
              containerView.bounds.size == tabBar.bounds.size
        else {
            return
        }
        containerView.isHidden = tabBar.isHidden
    }
}

private extension UIInterfaceOrientation {
    var asMask: UIInterfaceOrientationMask? {
        switch self {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return nil
        }
    }
}

private extension UIInterfaceOrientationMask {
    var asOrientation: UIInterfaceOrientation? {
        if contains(.portrait) {
            return .portrait
        } else if contains(.landscapeLeft) {
            return .landscapeLeft
        } else if contains(.landscapeRight) {
            return .landscapeRight
        } else if contains(.portraitUpsideDown) {
            return .portraitUpsideDown
        } else {
            return nil
        }
    }
}
