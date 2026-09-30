//
//  AppIconRevealViewController.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import NoorUI
import SwiftUI
import UIKit

/// Presents the app icon reveal full screen. Swiping can't dismiss it,
/// and the status bar turns light while night covers the screen.
@MainActor
final class AppIconRevealViewController: UIHostingController<AppIconRevealView> {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - newIcon: The icon the reveal ends on.
    ///   - onReplay: Called when a double tap on the icon replays the reveal.
    init(
        newIcon: Image,
        onContinue: @escaping () -> Void,
        onChooseAnotherIcon: (() -> Void)?,
        onReplay: @escaping () -> Void
    ) {
        super.init(rootView: AppIconRevealView(
            newIcon: newIcon,
            onContinue: onContinue,
            onChooseAnotherIcon: onChooseAnotherIcon,
            onNightChange: { _ in },
            onReplay: onReplay
        ))
        // Night updates this controller's status bar, so the view is replaced once `self` exists.
        rootView = AppIconRevealView(
            newIcon: newIcon,
            onContinue: onContinue,
            onChooseAnotherIcon: onChooseAnotherIcon,
            onNightChange: { [weak self] isNight in
                self?.showsLightStatusBar = isNight
            },
            onReplay: onReplay
        )
        modalPresentationStyle = .fullScreen
        modalTransitionStyle = .crossDissolve
        isModalInPresentation = true
    }

    @available(*, unavailable)
    @MainActor
    dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override var preferredStatusBarStyle: UIStatusBarStyle {
        showsLightStatusBar ? .lightContent : .default
    }

    /// The layout needs a portrait phone; iPad centers the content in any orientation.
    /// The trait collection's idiom can be unspecified during presentation, so this asks the device.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .portrait : .all
    }

    // MARK: Private

    private var showsLightStatusBar = false {
        didSet {
            guard showsLightStatusBar != oldValue else {
                return
            }
            NoorAnimation.animate { [weak self] in
                self?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}
