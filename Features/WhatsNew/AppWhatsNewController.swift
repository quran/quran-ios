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
import UIKit
import VLogging
import WhatsNewKit

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
                    self.present(versions, in: parent)
                }
            } else {
                logger.info("Ignoring whats new")
            }
        }
    }

    // MARK: Private

    private let analytics: AnalyticsLibrary
    private let store = AppWhatsNewVersionStore()

    private func present(_ versions: [WhatsNewVersion], in parent: UIViewController) {
        let whatsNewItems = versions.flatMap(\.items).map(\.whatsNewItem)

        let whatsNew = WhatsNew(
            title: l("new.title"),
            items: whatsNewItems
        )

        // custom whats new configuration
        var configuration = WhatsNewViewController.Configuration()

        configuration.completionButton.title = l("new.action")
        configuration.completionButton.action = .custom { vc in
            vc.dismiss(animated: true)
            logger.info("WhatsNew continue button tapped")
        }
        configuration.titleView.titleMode = .scrolls

        configuration.tintColor = .appIdentity
        configuration.backgroundColor = .systemBackground
        configuration.titleView.titleColor = .label
        configuration.itemsView.titleColor = .label
        configuration.itemsView.subtitleColor = .secondaryLabel
        configuration.itemsView.titleFont = .preferredFont(forTextStyle: .title2)
        configuration.itemsView.subtitleFont = .preferredFont(forTextStyle: .subheadline)

        // Initialize WhatsNewViewController with WhatsNew
        if let whatsNewViewController = WhatsNewViewController(
            whatsNew: whatsNew,
            configuration: configuration,
            versionStore: store
        ) {
            analytics.presentWhatsNew(versions: versions.map(\.version))
            parent.present(whatsNewViewController, animated: true)
        }
    }

    private nonisolated func whatsNewItems(after lastSeen: String?, whatsNew: AppWhatsNew) -> [WhatsNewVersion] {
        guard let lastSeen else {
            return whatsNew.versions
        }
        return whatsNew.versions.filter { $0.version.compare(lastSeen, options: .numeric) == .orderedDescending }
    }

    private nonisolated func whatsNew() -> AppWhatsNew {
        let url = Bundle.main.url(forResource: "whats-new", withExtension: "plist")!

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
