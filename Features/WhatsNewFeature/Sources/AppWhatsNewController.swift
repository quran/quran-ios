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
import FeaturesSupport
import SystemDependencies
#endif
import NoorUI
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
    ///   - bundle: Reads the build number, which TestFlight builds remember with the seen sync reveal.
    ///   - appDistribution: Tells TestFlight builds apart.
    ///   - authenticationClient: Signed-in users skip the sync reveal; its Sign In signs in with it.
    public init(
        analytics: AnalyticsLibrary,
        launchVersion: LaunchVersionUpdate,
        appIconCatalog: AppIconCatalog,
        bundle: SystemBundle,
        appDistribution: AppDistribution,
        authenticationClient: any AuthenticationClient
    ) {
        self.analytics = analytics
        self.launchVersion = launchVersion
        self.appIconCatalog = appIconCatalog
        self.bundle = bundle
        self.appDistribution = appDistribution
        self.authenticationClient = authenticationClient
    }
    #else
    /// - Parameters:
    ///   - launchVersion: How this launch relates to the previous one,
    ///     captured before the launch commits the current app version.
    ///   - appIconCatalog: The app's icons. The reveal shows its default icon.
    public init(analytics: AnalyticsLibrary, launchVersion: LaunchVersionUpdate, appIconCatalog: AppIconCatalog) {
        self.analytics = analytics
        self.launchVersion = launchVersion
        self.appIconCatalog = appIconCatalog
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
        let available = AppWhatsNew(versions: whatsNew.versions.filter { $0.reveal?.isAvailable ?? true })
        #if QURAN_SYNC
        // Only a TestFlight build can show the seen sync reveal again, so only then ask for the channel.
        if canPresentAgainOnTestFlight(available) {
            await resolveTestFlightBuild()
        }
        let plan = AppWhatsNewPlan(
            whatsNew: available,
            lastSeenVersion: store.lastSeenVersion,
            lastSeenBuild: store.lastSeenBuild,
            launchVersion: launchVersion,
            testFlightBuild: testFlightBuild
        )
        #else
        let plan = AppWhatsNewPlan(whatsNew: available, lastSeenVersion: store.lastSeenVersion, launchVersion: launchVersion)
        #endif
        switch plan {
        case .none:
            return []
        case .markSeen(let version):
            logger.info("WhatsNew: first launch, marking \(version) as seen")
            markSeen(version)
            return []
        case .present(let versions):
            #if QURAN_SYNC
            return await skippingSyncRevealIfSignedIn(versions)
            #else
            return versions
            #endif
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
    private let store = AppWhatsNewVersionStore()

    #if QURAN_SYNC
    /// How long to wait for the App Store to say whether this is TestFlight before assuming it isn't.
    private static let distributionTimeout: TimeInterval = 2

    private let bundle: SystemBundle
    private let appDistribution: AppDistribution
    private let authenticationClient: any AuthenticationClient

    /// The build this TestFlight launch runs, or `nil` outside TestFlight or until a rule needs it.
    private var testFlightBuild: String?
    private var hasResolvedTestFlightBuild = false
    #endif

    /// Records `version` as seen. Sync builds also record the TestFlight build it was seen on,
    /// and never move back to an older version, such as an older reveal after the sync reveal is skipped.
    private func markSeen(_ version: String) {
        #if QURAN_SYNC
        if let lastSeenVersion = store.lastSeenVersion,
           lastSeenVersion.compare(version, options: .numeric) == .orderedDescending
        {
            return
        }
        store.lastSeenVersion = version
        store.lastSeenBuild = testFlightBuild
        #else
        store.lastSeenVersion = version
        #endif
    }

    #if QURAN_SYNC
    /// Whether the sync reveal of the running version was seen, so a new TestFlight build could show it again.
    private func canPresentAgainOnTestFlight(_ whatsNew: AppWhatsNew) -> Bool {
        guard let lastSeenVersion = store.lastSeenVersion else {
            return false
        }
        return whatsNew.versions.contains { version in
            version.reveal == .sync
                && version.version.compare(lastSeenVersion, options: .numeric) == .orderedSame
                && version.version.isSameVersion(as: launchVersion.currentVersion)
        }
    }

    /// Reads the TestFlight build once. A slow or offline App Store lookup counts as not TestFlight.
    private func resolveTestFlightBuild() async {
        guard !hasResolvedTestFlightBuild else {
            return
        }
        hasResolvedTestFlightBuild = true
        let channel = await Self.channel(of: appDistribution, timeout: Self.distributionTimeout)
        testFlightBuild = channel == .testFlight ? bundle.infoValue(forKey: "CFBundleVersion") as? String : nil
    }

    private static func channel(of distribution: AppDistribution, timeout: TimeInterval) async -> AppDistributionChannel {
        await withCheckedContinuation { continuation in
            let resume = ResumeOnce(continuation)
            Task { @MainActor in
                resume(await distribution.channel)
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                resume(.appStore)
            }
        }
    }

    private func skippingSyncRevealIfSignedIn(_ versions: [WhatsNewVersion]) async -> [WhatsNewVersion] {
        guard let syncVersion = versions.filter({ $0.reveal == .sync }).latestVersion else {
            return versions
        }
        // Seeing or skipping the reveal records the TestFlight build it was seen on.
        await resolveTestFlightBuild()
        guard await isSignedIn() else {
            return versions
        }
        logger.info("WhatsNew: signed in to Quran.com, skipping the sync reveal of \(syncVersion)")
        analytics.skipSyncReveal(version: syncVersion)
        markSeen(syncVersion)
        return versions.filter { $0.reveal != .sync }
    }

    /// Whether the user is signed in, once MobileSync has read the stored session.
    ///
    /// At launch `authenticationState` reads signed out until the session is read, so this waits for the
    /// first signed-in user update, which comes once it is read, without a network refresh.
    private func isSignedIn() async -> Bool {
        do {
            for try await user in authenticationClient.loggedInUserUpdates {
                // A nil user can also be a signed-in session whose profile isn't known yet.
                return user != nil ? true : await authenticationClient.authenticationState == .authenticated
            }
        } catch {
            logger.error("WhatsNew: failed to read the signed-in user: \(error)")
        }
        // The updates ended before the first one; the restore waits for the stored session.
        return await authenticationClient.safelyRestoreState() == .authenticated
    }
    #endif

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
                    self?.signIn(from: parent)
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

    /// Starts the Quran.com sign-in once the reveal is gone.
    private func signIn(from viewController: UIViewController) {
        Task { [authenticationClient, analytics] in
            do {
                try await QuranSyncSignIn.signIn(
                    on: viewController,
                    authenticationClient: authenticationClient,
                    analytics: analytics,
                    source: .whatsNew
                )
            } catch {
                viewController.showErrorAlert(error: error)
            }
        }
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

#if QURAN_SYNC
/// Resumes a continuation with the first value it gets and ignores the rest.
@MainActor
private final class ResumeOnce<Value> {
    // MARK: Lifecycle

    init(_ continuation: CheckedContinuation<Value, Never>) {
        self.continuation = continuation
    }

    // MARK: Internal

    func callAsFunction(_ value: Value) {
        continuation?.resume(returning: value)
        continuation = nil
    }

    // MARK: Private

    private var continuation: CheckedContinuation<Value, Never>?
}
#endif

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
