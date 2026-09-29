//
//  AppWhatsNewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import AppMigrator
import NoorUI
import UIKit
import VLogging

@MainActor
public class AppWhatsNewController {
    // MARK: Lifecycle

    /// - Parameters:
    ///   - launchVersion: How this launch relates to the previous one,
    ///     captured before the launch commits the current app version.
    ///   - appIconCatalog: The app's icons. The reveal shows its default icon.
    public init(analytics: AnalyticsLibrary, launchVersion: LaunchVersionUpdate, appIconCatalog: AppIconCatalog) {
        self.analytics = analytics
        self.launchVersion = launchVersion
        self.appIconCatalog = appIconCatalog
    }

    // MARK: Public

    /// Presents what's new since the last seen version.
    /// - Parameter onChooseAnotherIcon: Opens the App Icon list after the reveal dismisses.
    ///   The reveal offers "Choose Another Icon" only when it is set.
    public func presentWhatsNewIfNeeded(from parent: UIViewController, onChooseAnotherIcon: (() -> Void)?) {
        Task { [weak parent] in
            let whatsNew = await Self.bundledWhatsNew()
            let versions = versionsToPresent(in: whatsNew)
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
    func versionsToPresent(in whatsNew: AppWhatsNew) -> [WhatsNewVersion] {
        let plan = AppWhatsNewPlan(
            whatsNew: whatsNew,
            lastSeenVersion: store.lastSeenVersion,
            launchVersion: launchVersion
        )
        switch plan {
        case .none:
            return []
        case .markSeen(let version):
            logger.info("WhatsNew: first launch, marking \(version) as seen")
            store.lastSeenVersion = version
            return []
        case .present(let versions):
            return versions
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

    /// Presents the app icon reveal when a version has one, otherwise the feature list.
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
            store.lastSeenVersion = version
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
            }
        )
        parent.present(viewController, animated: true)
    }

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
        store.lastSeenVersion = version

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

private extension AnalyticsLibrary {
    func presentWhatsNew(versions: [String]) {
        logEvent("PresentingWhatsNew", value: versions.joined(separator: ","))
    }

    func presentAppIconReveal(version: String) {
        logEvent("PresentingAppIconReveal", value: version)
    }

    func appIconReveal(_ action: AppIconRevealAction, version: String) {
        switch action {
        case .continue:
            logEvent("AppIconRevealContinue", value: version)
        case .chooseAnotherIcon:
            logEvent("AppIconRevealChooseAnotherIcon", value: version)
        }
    }
}
