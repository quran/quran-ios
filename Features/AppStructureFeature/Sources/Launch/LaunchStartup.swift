//
//  LaunchStartup.swift
//  Quran
//
//  Created by Afifi, Mohamed on 8/8/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import AppDependencies
import AppMigrationFeature
import AppMigrator
import AudioUpdater
import Crashing
import NoorUI
import QuranKit
import ReadingService
import SettingsService
import SwiftUI
import UIKit
import VLogging

@MainActor
public final class LaunchStartup {
    // MARK: Lifecycle

    init(
        launchStores: LaunchStores,
        downloadBackupMigrator: DownloadBackupMigrator,
        audioUpdater: AudioUpdater,
        fileSystemMigrator: FileSystemMigrator,
        recitersPathMigrator: RecitersPathMigrator,
        reviewService: ReviewService,
        appIconService: AppIconService
    ) {
        self.launchStores = launchStores
        self.downloadBackupMigrator = downloadBackupMigrator
        self.audioUpdater = audioUpdater
        self.fileSystemMigrator = fileSystemMigrator
        self.recitersPathMigrator = recitersPathMigrator
        self.reviewService = reviewService
        self.appIconService = appIconService
    }

    deinit {
        if let protectedDataObserver {
            notificationCenter.removeObserver(protectedDataObserver)
        }
        if let foregroundObserver {
            notificationCenter.removeObserver(foregroundObserver)
        }
    }

    // MARK: Public

    public func launch(from window: UIWindow) {
        // The accent follows the icon iOS shows, before any screen reads it.
        appIconService.applyAccent(to: window)
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

    public func handleIncomingUrl(urlContext: UIOpenURLContext) {
        let url = urlContext.url
        guard let deepLink = QuranDeepLink(url: url, quran: ReadingPreferences.shared.reading.quran) else {
            logger.notice("Deep link: ignoring unsupported url \(url)")
            return
        }
        logger.info("Deep link: handling \(url)")
        navigate(to: deepLink)
    }

    // MARK: Private

    private let fileSystemMigrator: FileSystemMigrator
    private let recitersPathMigrator: RecitersPathMigrator
    private let launchStores: LaunchStores
    private let downloadBackupMigrator: DownloadBackupMigrator
    private let audioUpdater: AudioUpdater
    private let reviewService: ReviewService
    private let appIconService: AppIconService
    private let crashApplicationObserver = CrashApplicationObserver()
    private let notificationCenter = NotificationCenter.default

    private let appMigrator = AppMigrator()
    private var appViewController: AppViewController?
    private var launchScreen: UIViewController?
    private var pendingDeepLink: QuranDeepLink?
    private var protectedDataObserver: NSObjectProtocol?
    private var protectedDataStartupState = ProtectedDataStartupState()
    private var storeOpenStartupState = StoreOpenStartupState()
    private var foregroundObserver: NSObjectProtocol?

    private func perform(_ action: ProtectedDataStartupState.Action, window: UIWindow) {
        switch action {
        case .start:
            stopObservingProtectedData()
            crashContext.setProtectedDataAvailable(UIApplication.shared.isProtectedDataAvailable)
            openStores(window: window)
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

    /// Opens the stores before anything reads them, so a device that's out of storage shows
    /// a screen it can recover from instead of crashing on every launch.
    private func openStores(window: UIWindow) {
        crashContext.setStartupPhase("opening_stores")
        logger.info("Crash context: startup phase opening_stores")
        showLaunchScreenIfNeeded(window: window)
        let launchStores = launchStores
        Task { [weak self, weak window] in
            let result = await launchStores.open()
            guard let self, let window else { return }
            handleOpenedStores(result, window: window)
        }
    }

    /// Shows the app's launch screen until the app is built, so the window isn't black while
    /// the stores open.
    private func showLaunchScreenIfNeeded(window: UIWindow) {
        guard window.rootViewController == nil,
              let name = Bundle.main.object(forInfoDictionaryKey: "UILaunchStoryboardName") as? String,
              Bundle.main.path(forResource: name, ofType: "storyboardc") != nil,
              let launchScreen = UIStoryboard(name: name, bundle: .main).instantiateInitialViewController()
        else {
            return
        }
        self.launchScreen = launchScreen
        window.rootViewController = launchScreen
        window.makeKeyAndVisible()
    }

    private func handleOpenedStores(_ result: Result<AppDependencies, LaunchStoreError>, window: UIWindow) {
        switch result {
        case let .success(dependencies):
            guard storeOpenStartupState.storesOpened() == .continueLaunch else { return }
            stopObservingForeground()
            #if QURAN_SYNC
            startLegacyDataImport(dependencies: dependencies)
            #endif
            upgradeIfNeeded(window: window, dependencies: dependencies)
        case let .failure(.storageFull(store, error)):
            crashContext.setStartupPhase("storage_full")
            logger.error("Crash context: startup phase storage_full. The \(store) store failed to open. Error: \(error)")
            guard storeOpenStartupState.storageFull() == .showStorageFull else { return }
            crasher.recordError(
                StoreStorageFullError(store: store, underlying: error),
                reason: "Launch couldn't open the \(store) store because the device is out of storage"
            )
            showStorageFull(window: window)
            observeForeground(window: window)
        case let .failure(.failed(message)):
            fatalError(message)
        }
    }

    private func retryOpeningStores(window: UIWindow) {
        guard storeOpenStartupState.isWaitingForStorage else { return }
        logger.info("Launch: opening the stores again")
        openStores(window: window)
    }

    private func showStorageFull(window: UIWindow) {
        let view = StorageFullView { [weak self, weak window] in
            guard let self, let window else { return }
            retryOpeningStores(window: window)
        }
        window.rootViewController = UIHostingController(rootView: view)
        window.makeKeyAndVisible()
    }

    /// The app may have launched in the background, so it tries again each time the user returns to it.
    private func observeForeground(window: UIWindow) {
        guard foregroundObserver == nil else { return }
        foregroundObserver = notificationCenter.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self, weak window] _ in
            Task { @MainActor in
                guard let self, let window else { return }
                self.retryOpeningStores(window: window)
            }
        }
    }

    private func stopObservingForeground() {
        guard let foregroundObserver else { return }
        notificationCenter.removeObserver(foregroundObserver)
        self.foregroundObserver = nil
    }

    private func upgradeIfNeeded(window: UIWindow, dependencies: AppDependencies) {
        registerMigrators(dependencies: dependencies)
        // Read before `migrationStatus()` or `migrate()` commits the current version.
        let launchVersion = appMigrator.launchVersion
        switch appMigrator.migrationStatus() {
        case .noMigration:
            showApp(window: window, launchVersion: launchVersion, dependencies: dependencies)
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
                showApp(window: window, launchVersion: launchVersion, dependencies: dependencies)
            }
        }
    }

    private func showApp(window: UIWindow, launchVersion: LaunchVersionUpdate, dependencies: AppDependencies) {
        if self.appViewController != nil {
            return
        }

        updateAudioIfNeeded(launchVersion: launchVersion)
        crashContext.setStartupPhase("building_ui")
        logger.info("Crash context: startup phase building_ui")

        // Replacing the launch screen looks like a normal launch; replacing any other screen cross-fades.
        let wasUpdated = window.rootViewController.map { $0 !== launchScreen } ?? false
        launchScreen = nil

        let appViewController = AppBuilder(container: dependencies).build(launchVersion: launchVersion)
        self.appViewController = appViewController

        if wasUpdated {
            appViewController.transition(to: window, duration: 0.3, options: .transitionCrossDissolve)
        } else {
            appViewController.launch(from: window)
            reviewService.checkForReview(in: window)
        }
        crashContext.setStartupPhase("ready")
        logger.info("Crash context: startup phase ready")

        if let pendingDeepLink {
            self.pendingDeepLink = nil
            appViewController.navigate(to: pendingDeepLink)
        }
    }

    /// Links can arrive while the app is still migrating or waiting for protected data,
    /// so they are replayed once the app UI exists.
    private func navigate(to deepLink: QuranDeepLink) {
        guard let appViewController else {
            pendingDeepLink = deepLink
            return
        }
        appViewController.navigate(to: deepLink)
    }

    private func registerMigrators(dependencies: AppDependencies) {
        appMigrator.register(migrator: fileSystemMigrator, for: "1.16.0")
        appMigrator.register(migrator: recitersPathMigrator, for: "1.19.1")
        appMigrator.register(migrator: downloadBackupMigrator, for: "2.6.9")
        #if QURAN_SYNC
        // Upgrades import legacy data once before showing the UI.
        appMigrator.register(
            migrator: LegacyDataMigrator(coordinator: dependencies.legacyDataImportCoordinator),
            for: "3.1.0"
        )
        #endif
    }

    #if QURAN_SYNC
    /// Imports legacy data on every launch and after each change to the legacy store.
    /// Resolving the coordinator opens MobileSync, which needs protected data.
    private func startLegacyDataImport(dependencies: AppDependencies) {
        let coordinator = dependencies.legacyDataImportCoordinator
        Task { await coordinator.start() }
    }
    #endif

    private func updateAudioIfNeeded(launchVersion: LaunchVersionUpdate) {
        // don't run audio updater after upgrading the app
        guard case .sameVersion = launchVersion else {
            return
        }
        Task {
            await audioUpdater.updateAudioIfNeeded()
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
