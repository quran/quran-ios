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
import UIKit
import WhatsNewFeature

protocol AppPresenter: UITabBarController {}

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

    // MARK: Orientation

    override open var shouldAutorotate: Bool {
        visibleViewController?.shouldAutorotate ?? super.shouldAutorotate
    }

    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        visibleViewController?.supportedInterfaceOrientations ?? super.supportedInterfaceOrientations
    }

    // MARK: View lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        configureFloatingLiquidGlassTabBar()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutFloatingTabBar()
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        let targetMask = tabBarController.supportedInterfaceOrientations
        if let currentMask = tabBarController.view.window?.windowScene?.interfaceOrientation.asMask {
            if !targetMask.contains(currentMask),
               let interface = targetMask.asOrientation {
                UIDevice.current.setValue(interface.rawValue, forKey: "orientation")
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        whatsNewController.presentWhatsNewIfNeeded(from: self)
    }

    // MARK: - Liquid Glass Tab Bar (Apple-style)

    private func configureFloatingLiquidGlassTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        if #available(iOS 18.0, *) {
            appearance.backgroundEffect = UIGlassEffect(style: .system)
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        } else {
            appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        }

        appearance.shadowColor = .clear

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor.white.withAlphaComponent(0.6)
    }

    private func layoutFloatingTabBar() {
        let height: CGFloat = 64
        let horizontalInset: CGFloat = 20
        let bottomInset: CGFloat = 18

        tabBar.frame = CGRect(
            x: horizontalInset,
            y: view.bounds.height - height - bottomInset,
            width: view.bounds.width - horizontalInset * 2,
            height: height
        )

        // FULL capsule
        tabBar.layer.cornerRadius = height / 2
        tabBar.layer.masksToBounds = true

        // smooth floating shadow
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.35
        tabBar.layer.shadowOffset = CGSize(width: 0, height: 10)
        tabBar.layer.shadowRadius = 30
    }

    // MARK: Private

    private let interactor: AppInteractor
    private let whatsNewController: AppWhatsNewController

    private var visibleViewController: UIViewController? {
        presentedViewController ?? selectedViewController
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
        if contains(.portrait) { return .portrait }
        if contains(.landscapeLeft) { return .landscapeLeft }
        if contains(.landscapeRight) { return .landscapeRight }
        if contains(.portraitUpsideDown) { return .portraitUpsideDown }
        return nil
    }
}
