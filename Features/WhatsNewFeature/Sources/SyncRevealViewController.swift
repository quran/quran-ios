//
//  SyncRevealViewController.swift
//
//
//  Created by Mohamed Afifi on 2026-11-11.
//

import SwiftUI
import UIKit

/// Presents the sync reveal full screen with a light status bar. Swiping can't dismiss it.
@MainActor
final class SyncRevealViewController: UIHostingController<SyncRevealView> {
    // MARK: Lifecycle

    init(icon: Image, onSignIn: @escaping () -> Void, onNotNow: @escaping () -> Void) {
        super.init(rootView: SyncRevealView(icon: icon, onSignIn: onSignIn, onNotNow: onNotNow))
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
        .lightContent
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        UIDevice.current.userInterfaceIdiom == .phone ? .allButUpsideDown : .all
    }
}
