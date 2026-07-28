//
//  AppWhatsNewController.swift
//  Quran
//
//  Created by Afifi, Mohamed on 10/25/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Analytics
import Localization
import NoorUI
import SwiftUI
import UIKit
import VLogging

@MainActor
public class AppWhatsNewController {
    // MARK: Lifecycle

    public init(analytics: AnalyticsLibrary) {
        self.analytics = analytics
    }

    // MARK: Public

    public func presentWhatsNewIfNeeded(from parent: UIViewController) {
        let lastSeenVersion = store.lastSeenVersion

        // TODO: Use async/await
        DispatchQueue.global().async {
            let whatsNew = self.whatsNew()
            let versions = self.whatsNewItems(after: lastSeenVersion, whatsNew: whatsNew)
            if !versions.isEmpty {
                DispatchQueue.main.async {
                    self.presentAnnouncement(before: versions, in: parent)
                }
            } else {
                logger.info("Ignoring whats new")
            }
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let store = AppWhatsNewVersionStore()

    private func presentAnnouncement(before versions: [WhatsNewVersion], in parent: UIViewController) {
        let navigationController = UINavigationController()
        let view = AppIconAnnouncementView { [weak self, weak navigationController] in
            guard let self, let navigationController else { return }

            let whatsNewViewController = makeWhatsNewViewController(
                versions: versions,
                navigationController: navigationController
            )

            analytics.presentWhatsNew(versions: versions.map(\.version))
            navigationController.pushViewController(whatsNewViewController, animated: true)
        }
        let announcementViewController = UIHostingController(rootView: view)
        announcementViewController.navigationItem.title = l("new.title")
        announcementViewController.navigationItem.largeTitleDisplayMode = .never

        navigationController.setViewControllers([announcementViewController], animated: false)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.sheetPresentationController?.detents = [.large()]

        parent.present(navigationController, animated: true)
    }

    private func makeWhatsNewViewController(
        versions: [WhatsNewVersion],
        navigationController: UINavigationController
    ) -> UIViewController {
        let latestVersion = versions
            .map(\.version)
            .max { lhs, rhs in
                lhs.compare(rhs, options: .numeric) == .orderedAscending
            }

        let view = AppWhatsNewView(
            items: versions.flatMap(\.items),
            onContinue: { [weak navigationController] in
                navigationController?.dismiss(animated: true)
                logger.info("WhatsNew continue button tapped")
            }
        )
        let viewController = AppWhatsNewViewController(rootView: view)
        store.lastSeenVersion = latestVersion
        return viewController
    }

    private nonisolated func whatsNewItems(after lastSeen: String?, whatsNew: AppWhatsNew) -> [WhatsNewVersion] {
        guard let lastSeen else {
            return whatsNew.versions
        }
        return whatsNew.versions.filter { $0.version.compare(lastSeen, options: .numeric) == .orderedDescending }
    }

    private nonisolated func whatsNew() -> AppWhatsNew {
        let url = Bundle.module.url(forResource: "whats-new.plist", withExtension: "")!

        let data = try! Data(contentsOf: url) // swiftlint:disable:this force_try
        let decoder = PropertyListDecoder()
        let appWhatsNew = try! decoder.decode(AppWhatsNew.self, from: data) // swiftlint:disable:this force_try

        return appWhatsNew
    }
}

private extension AnalyticsLibrary {
    func presentWhatsNew(versions: [String]) {
        logEvent("PresentingWhatsNew", value: versions.joined(separator: ","))
    }
}
