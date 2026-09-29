//
//  AppIconListViewModel.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Analytics
import Combine
import NoorUI
import VLogging

/// Where the user opened the App Icon list from.
public enum AppIconListSource: String, Sendable {
    case settings
    case whatsNew
}

@MainActor
final class AppIconListViewModel: ObservableObject {
    // MARK: Lifecycle

    init(appIconService: AppIconService, analytics: AnalyticsLibrary, source: AppIconListSource) {
        self.appIconService = appIconService
        self.analytics = analytics
        selectedOption = appIconService.currentOption
        analytics.openingAppIcons(from: source)
    }

    // MARK: Internal

    @Published private(set) var selectedOption: AppIconOption
    @Published var error: Error?

    var sections: [AppIconCatalog.Section] {
        appIconService.catalog.sections
    }

    /// Changes the Home Screen icon. The selection moves only after iOS accepts the change.
    func select(_ option: AppIconOption) async {
        guard option != selectedOption, !isChangingIcon else {
            return
        }
        isChangingIcon = true
        defer { isChangingIcon = false }

        let previousOption = selectedOption
        logger.info("App icon: changing from \(previousOption.id) to \(option.id)")
        do {
            try await appIconService.set(option)
            selectedOption = option
            analytics.changeAppIcon(from: previousOption, to: option, error: nil)
        } catch {
            logger.error("App icon: failed to change to \(option.id). Error: \(error)")
            analytics.changeAppIcon(from: previousOption, to: option, error: error)
            self.error = error
        }
    }

    // MARK: Private

    private let appIconService: AppIconService
    private let analytics: AnalyticsLibrary
    private var isChangingIcon = false
}
