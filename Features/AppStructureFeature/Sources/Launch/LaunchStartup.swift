//
//  LaunchStartup.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppMigrationFeature
import AppMigrator
import AudioUpdater
import Crashing
import SettingsService
import UIKit
import VLogging

@MainActor
public final class LaunchStartup {
    // MARK: Lifecycle

    init(
        appBuilder: AppBuilder,
        audioUpdater: AudioUpdater,
        fileSystemMigrator: FileSystemMigrator,
        recitersPathMigrator: RecitersPathMigrator,
        reviewService: ReviewService
    ) {
        self.appBuilder = appBuilder
        self.audioUpdater = audioUpdater
        self.fileSystemMigrator = fileSystemMigrator
        self.recitersPathMigrator = recitersPathMigrator
        self.reviewService = reviewService
    }

    deinit {
        if let protectedDataObserver {
            notificationCenter.removeObserver(protectedDataObserver)
        }
    }

    // MARK: Public

    public func launch(from window: UIWindow) {
        crashApplicationObserver.start()
        crashContext.setStartupPhase("launching")
        #if QURAN_SYNC
        crashContext.setSyncState("initializing")
        #else
        crashContext.setSyncState("disabled")
        #endif
        logger.info("Crash context: startup phase launching")
        perform(
            protectedDataStartupState.launch(
                isProtectedDataAvailable: UIApplication.shared.isProtectedDataAvailable
            ),
            window: window
        )
    }

    // MARK: Private

    private let fileSystemMigrator: FileSystemMigrator
    private let recitersPathMigrator: RecitersPathMigrator
    private let appBuilder: AppBuilder
    private let audioUpdater: AudioUpdater
    private let reviewService: ReviewService
    private let crashApplicationObserver = CrashApplicationObserver()
    private let notificationCenter = NotificationCenter.default

    private let appMigrator = AppMigrator()
    private var appViewController: UIViewController?
    private var protectedDataObserver: NSObjectProtocol?
    private var protectedDataStartupState = ProtectedDataStartupState()

    private func perform(_ action: ProtectedDataStartupState.Action, window: UIWindow) {
        switch action {
        case .start:
            stopObservingProtectedData()
            crashContext.setProtectedDataAvailable(UIApplication.shared.isProtectedDataAvailable)
            upgradeIfNeeded(window: window)
        case .wait:
            waitForProtectedData(window: window)
        case .none:
            break
        }
    }

    private func waitForProtectedData(window: UIWindow) {
        crashContext.setStartupPhase("waiting_for_protected_data")
        logger.info("Crash context: startup waiting for protected data")

        protectedDataObserver = notificationCenter.addObserver(
            forName: UIApplication.protectedDataDidBecomeAvailableNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak window] _ in
            Task { @MainActor in
                guard let self, let window else { return }
                self.perform(
                    self.protectedDataStartupState.protectedDataDidBecomeAvailable(),
                    window: window
                )
            }
        }

        // Close the race where protected data becomes available between the
        // initial check and observer registration.
        if UIApplication.shared.isProtectedDataAvailable {
            perform(protectedDataStartupState.protectedDataDidBecomeAvailable(), window: window)
        }
    }

    private func stopObservingProtectedData() {
        guard let protectedDataObserver else { return }
        notificationCenter.removeObserver(protectedDataObserver)
        self.protectedDataObserver = nil
    }

    private func upgradeIfNeeded(window: UIWindow) {
        registerMigrators()
        switch appMigrator.migrationStatus() {
        case .noMigration:
            showApp(window: window)
        case let .migrate(blocksUI, titles):
            crashContext.setStartupPhase("migrating")
            logger.info("Crash context: startup phase migrating")
            if blocksUI {
                logger.notice("Performing long upgrade task: \(titles)")
                let migrationVC = MigrationViewController()
                migrationVC.setTitles(titles)
                window.rootViewController = migrationVC
                window.makeKeyAndVisible()
            }
            Task {
                await appMigrator.migrate()
                showApp(window: window)
            }
        }
    }

    private func showApp(window: UIWindow) {
        if self.appViewController != nil {
            return
        }

        updateAudioIfNeeded()
        crashContext.setStartupPhase("building_ui")
        logger.info("Crash context: startup phase building_ui")

        let wasUpdated = window.rootViewController != nil

        let appViewController = appBuilder.build()
        self.appViewController = appViewController

        if wasUpdated {
            appViewController.transition(to: window, duration: 0.3, options: .transitionCrossDissolve)
        } else {
            appViewController.launch(from: window)
            reviewService.checkForReview(in: window)
        }
        crashContext.setStartupPhase("ready")
        logger.info("Crash context: startup phase ready")
    }

    private func registerMigrators() {
        appMigrator.register(migrator: fileSystemMigrator, for: "1.16.0")
        appMigrator.register(migrator: recitersPathMigrator, for: "1.19.1")
    }

    private func updateAudioIfNeeded() {
        // don't run audio updater after upgrading the app
        if case .sameVersion = appMigrator.launchVersion {
            Task {
                await audioUpdater.updateAudioIfNeeded()
            }
        }
    }
}

struct ProtectedDataStartupState {
    enum Action: Equatable {
        case start
        case wait
        case none
    }

    mutating func launch(isProtectedDataAvailable: Bool) -> Action {
        guard phase == .idle else { return .none }
        if isProtectedDataAvailable {
            phase = .started
            return .start
        }
        phase = .waiting
        return .wait
    }

    mutating func protectedDataDidBecomeAvailable() -> Action {
        guard phase == .waiting else { return .none }
        phase = .started
        return .start
    }

    private enum Phase {
        case idle
        case waiting
        case started
    }

    private var phase = Phase.idle
}

private extension UIViewController {
    func launch(from window: UIWindow) {
        window.rootViewController = self
        window.makeKeyAndVisible()
    }

    func transition(to window: UIWindow, duration: TimeInterval, options: UIView.AnimationOptions) {
        window.switchRootViewController(to: self, duration: duration, options: options)
    }
}
