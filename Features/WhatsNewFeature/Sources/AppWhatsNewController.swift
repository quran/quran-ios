//
//  AppWhatsNewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import AppMigrator
#if QURAN_SYNC
import AuthenticationClient
#endif
import NoorUI
import SystemDependencies
import UIKit
import VLogging

@MainActor
public class AppWhatsNewController {
    // MARK: Lifecycle

    #if QURAN_SYNC
    /// - Parameters:
    ///   - launchVersion: How this launch relates to the previous one,
    ///     captured before the launch commits the current app version.
    ///   - appIconCatalog: The app's icons. The reveals show its default icon.
    ///   - bundle: Reads the build number, which TestFlight builds remember with the seen version.
    ///   - appDistribution: Tells TestFlight builds apart.
    ///   - authenticationClient: Signed-in users skip the sync reveal.
    ///   - signIn: Starts the Quran.com sign-in from the given screen, after the sync reveal dismisses.
    public init(
        analytics: AnalyticsLibrary,
        launchVersion: LaunchVersionUpdate,
        appIconCatalog: AppIconCatalog,
        bundle: SystemBundle,
        appDistribution: AppDistribution,
        authenticationClient: any AuthenticationClient,
        signIn: @escaping @MainActor (UIViewController) -> Void
    ) {
        self.analytics = analytics
        self.launchVersion = launchVersion
        self.appIconCatalog = appIconCatalog
        self.bundle = bundle
        self.appDistribution = appDistribution
        self.authenticationClient = authenticationClient
        self.signIn = signIn
    }
    #else
    /// - Parameters:
    ///   - launchVersion: How this launch relates to the previous one,
    ///     captured before the launch commits the current app version.
    ///   - appIconCatalog: The app's icons. The reveal shows its default icon.
    ///   - bundle: Reads the build number, which TestFlight builds remember with the seen version.
    ///   - appDistribution: Tells TestFlight builds apart.
    public init(
        analytics: AnalyticsLibrary,
        launchVersion: LaunchVersionUpdate,
        appIconCatalog: AppIconCatalog,
        bundle: SystemBundle,
        appDistribution: AppDistribution
    ) {
        self.analytics = analytics
        self.launchVersion = launchVersion
        self.appIconCatalog = appIconCatalog
        self.bundle = bundle
        self.appDistribution = appDistribution
    }
    #endif

    // MARK: Public

    /// Presents what's new since the last seen version.
    /// - Parameter onChooseAnotherIcon: Opens the App Icon list after the reveal dismisses.
    ///   The reveal offers "Choose Another Icon" only when it is set.
    public func presentWhatsNewIfNeeded(from parent: UIViewController, onChooseAnotherIcon: (() -> Void)?) {
        Task { [weak parent] in
            let whatsNew = await Self.bundledWhatsNew()
            let versions = await versionsToPresent(in: whatsNew)
            guard let parent, !versions.isEmpty else {
                logger.info("Ignoring whats new")
                return
            }
            present(versions, from: parent, onChooseAnotherIcon: onChooseAnotherIcon)
        }
    }

    // MARK: Internal

    /// Applies the show rules and returns the versions to present.
    /// A fresh install records every version as seen and presents nothing.
    /// Versions whose reveal this build can't show are left out, and signed-in users skip the sync reveal.
    func versionsToPresent(in whatsNew: AppWhatsNew) async -> [WhatsNewVersion] {
        testFlightBuild = await currentTestFlightBuild()
        let available = AppWhatsNew(versions: whatsNew.versions.filter { $0.reveal?.isAvailable ?? true })
        let plan = AppWhatsNewPlan(
            whatsNew: available,
            lastSeenVersion: store.lastSeenVersion,
            lastSeenBuild: store.lastSeenBuild,
            launchVersion: launchVersion,
            testFlightBuild: testFlightBuild
        )
        switch plan {
        case .none:
            return []
        case .markSeen(let version):
            logger.info("WhatsNew: first launch, marking \(version) as seen")
            markSeen(version)
            return []
        case .present(let versions):
            return await skippingSyncRevealIfSignedIn(versions)
        }
    }

    /// Loads `whats-new.plist` off the main actor.
    nonisolated static func bundledWhatsNew() async -> AppWhatsNew {
        let url = Bundle.module.url(forResource: "whats-new.plist", withExtension: "")!

        let data = try! Data(contentsOf: url) // swiftlint:disable:this force_try
        let decoder = PropertyListDecoder()
        let appWhatsNew = try! decoder.decode(AppWhatsNew.self, from: data) // swiftlint:disable:this force_try

        return appWhatsNew
    }

    /// Presents the sync or app icon reveal when a version has one, otherwise the feature list.
    func present(
        _ versions: [WhatsNewVersion],
        from parent: UIViewController,
        onChooseAnotherIcon: (() -> Void)?
    ) {
        guard let latestVersion = versions.latestVersion else {
            return
        }
        analytics.presentWhatsNew(versions: versions.map(\.version))

        let items = versions.flatMap(\.items)
        #if QURAN_SYNC
        if versions.contains(where: { $0.reveal == .sync }) {
            presentSyncReveal(version: latestVersion, items: items, from: parent)
            return
        }
        #endif
        if versions.contains(where: { $0.reveal == .appIcon }) {
            presentAppIconReveal(
                version: latestVersion,
                items: items,
                from: parent,
                onChooseAnotherIcon: onChooseAnotherIcon
            )
        } else if !items.isEmpty {
            presentFeatureList(items, version: latestVersion, from: parent)
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let launchVersion: LaunchVersionUpdate
    private let appIconCatalog: AppIconCatalog
    private let bundle: SystemBundle
    private let appDistribution: AppDistribution
    #if QURAN_SYNC
    private let authenticationClient: any AuthenticationClient
    private let signIn: @MainActor (UIViewController) -> Void
    #endif
    private let store = AppWhatsNewVersionStore()

    /// The build this TestFlight launch runs, or `nil` outside TestFlight. Read with the show rules.
    private var testFlightBuild: String?

    private func currentTestFlightBuild() async -> String? {
        guard await appDistribution.channel == .testFlight else {
            return nil
        }
        return bundle.infoValue(forKey: "CFBundleVersion") as? String
    }

    /// Records `version` as seen, with the TestFlight build it was seen on.
    /// Never moves back to an older version, such as an older feature list after a newer reveal is skipped.
    private func markSeen(_ version: String) {
        if let lastSeenVersion = store.lastSeenVersion,
           lastSeenVersion.compare(version, options: .numeric) == .orderedDescending
        {
            return
        }
        store.lastSeenVersion = version
        store.lastSeenBuild = testFlightBuild
    }

    private func skippingSyncRevealIfSignedIn(_ versions: [WhatsNewVersion]) async -> [WhatsNewVersion] {
        #if QURAN_SYNC
        let syncVersions = versions.filter { $0.reveal == .sync }
        guard let syncVersion = syncVersions.latestVersion,
              await authenticationClient.authenticationState == .authenticated
        else {
            return versions
        }
        logger.info("WhatsNew: signed in to Quran.com, skipping the sync reveal of \(syncVersion)")
        analytics.skipSyncReveal(version: syncVersion)
        markSeen(syncVersion)
        return versions.filter { $0.reveal != .sync }
        #else
        return versions
        #endif
    }

    private func presentAppIconReveal(
        version: String,
        items: [WhatsNewItem],
        from parent: UIViewController,
        onChooseAnotherIcon: (() -> Void)?
    ) {
        analytics.presentAppIconReveal(version: version)

        // Either action dismisses the reveal, so only the first tap counts,
        // even when both actions are tapped at once.
        var isDismissing = false
        let dismiss = { [weak self, weak parent] (action: AppIconRevealAction, completion: (() -> Void)?) in
            guard let self, !isDismissing else { return }
            isDismissing = true
            logger.info("WhatsNew: app icon reveal \(action.rawValue) tapped")
            analytics.appIconReveal(action, version: version)
            markSeen(version)
            parent?.dismiss(animated: true, completion: completion)
        }

        let viewController = AppIconRevealViewController(
            newIcon: appIconCatalog.defaultOption.previewImage,
            onContinue: { [weak self, weak parent] in
                dismiss(.continue) { [weak self, weak parent] in
                    // Older unseen versions keep their feature list.
                    guard let self, let parent, !items.isEmpty else { return }
                    presentFeatureList(items, version: version, from: parent)
                }
            },
            onChooseAnotherIcon: onChooseAnotherIcon.map { chooseAnotherIcon in
                { dismiss(.chooseAnotherIcon, chooseAnotherIcon) }
            },
            onReplay: { [weak self] in
                logger.info("WhatsNew: app icon reveal replayed")
                self?.analytics.replayAppIconReveal(version: version)
            }
        )
        parent.present(viewController, animated: true)
    }

    #if QURAN_SYNC
    /// The sync reveal replaces older reveals; "Not now" still shows older feature items.
    private func presentSyncReveal(version: String, items: [WhatsNewItem], from parent: UIViewController) {
        analytics.presentSyncReveal(version: version)

        // Either action dismisses the reveal, so only the first tap counts.
        var isDismissing = false
        let dismiss = { [weak self, weak parent] (action: SyncRevealAction, completion: @escaping (UIViewController) -> Void) in
            guard let self, !isDismissing else { return }
            isDismissing = true
            logger.info("WhatsNew: sync reveal \(action.rawValue) tapped")
            analytics.syncReveal(action, version: version)
            markSeen(version)
            parent?.dismiss(animated: true) { [weak parent] in
                guard let parent else { return }
                completion(parent)
            }
        }

        let viewController = SyncRevealViewController(
            icon: appIconCatalog.defaultOption.previewImage,
            onSignIn: { [weak self] in
                dismiss(.signIn) { parent in
                    self?.signIn(parent)
                }
            },
            onNotNow: { [weak self] in
                dismiss(.notNow) { parent in
                    // Older unseen versions keep their feature list.
                    guard !items.isEmpty else { return }
                    self?.presentFeatureList(items, version: version, from: parent)
                }
            }
        )
        parent.present(viewController, animated: true)
    }
    #endif

    private func presentFeatureList(_ items: [WhatsNewItem], version: String, from parent: UIViewController) {
        let navigationController = UINavigationController()
        let view = AppWhatsNewView(
            items: items,
            onContinue: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
                logger.info("WhatsNew continue button tapped")
            }
        )
        let viewController = AppWhatsNewViewController(rootView: view)
        markSeen(version)

        navigationController.setViewControllers([viewController], animated: false)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.isModalInPresentation = true
        navigationController.sheetPresentationController?.detents = [.large()]

        parent.present(navigationController, animated: true)
    }
}

private enum AppIconRevealAction: String {
    case `continue`
    case chooseAnotherIcon = "choose another icon"
}

private enum SyncRevealAction: String {
    case signIn = "sign in"
    case notNow = "not now"
}

private extension AnalyticsLibrary {
    func presentWhatsNew(versions: [String]) {
        logEvent("PresentingWhatsNew", value: versions.joined(separator: ","))
    }

    func presentAppIconReveal(version: String) {
        logEvent("PresentingAppIconReveal", value: version)
    }

    func replayAppIconReveal(version: String) {
        logEvent("AppIconRevealReplay", value: version)
    }

    func appIconReveal(_ action: AppIconRevealAction, version: String) {
        switch action {
        case .continue:
            logEvent("AppIconRevealContinue", value: version)
        case .chooseAnotherIcon:
            logEvent("AppIconRevealChooseAnotherIcon", value: version)
        }
    }

    func presentSyncReveal(version: String) {
        logEvent("PresentingSyncReveal", value: version)
    }

    func skipSyncReveal(version: String) {
        logEvent("SyncRevealSkippedSignedIn", value: version)
    }

    func syncReveal(_ action: SyncRevealAction, version: String) {
        switch action {
        case .signIn:
            logEvent("SyncRevealSignIn", value: version)
        case .notNow:
            logEvent("SyncRevealNotNow", value: version)
        }
    }
}
