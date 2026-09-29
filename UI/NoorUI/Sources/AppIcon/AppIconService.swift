//
//  AppIconService.swift
//
//
//  Created by Mohamed Afifi on 2026-09-29.
//

import Combine
import SystemDependencies
import UIKit
import VLogging

/// Changes the app's Home Screen icon and keeps the interface accent in step with it.
///
/// iOS owns the current icon, so nothing is persisted. The accent follows the icon at launch
/// and after every change.
@MainActor
public final class AppIconService {
    // MARK: Lifecycle

    public init(catalog: AppIconCatalog, iconAccess: AlternateIconAccess, bundle: SystemBundle) {
        self.catalog = catalog
        self.iconAccess = iconAccess
        self.bundle = bundle
    }

    // MARK: Public

    public let catalog: AppIconCatalog

    /// Whether the app can change its icon. It needs platform support, which Mac Catalyst lacks,
    /// and alternate icons declared in the main bundle's Info.plist.
    public var isAvailable: Bool {
        iconAccess.supportsAlternateIcons && declaresAlternateIcons
    }

    /// The icon iOS shows for the app.
    public var currentOption: AppIconOption {
        catalog.option(alternateIconName: iconAccess.alternateIconName)
    }

    /// Emits the current icon, then every icon the app changes to.
    public var currentOptionPublisher: AnyPublisher<AppIconOption, Never> {
        AppIconChanges.alternateIconNames
            .map { [catalog] alternateIconName in catalog.option(alternateIconName: alternateIconName) }
            .prepend(currentOption)
            .eraseToAnyPublisher()
    }

    /// Makes the accent follow the icon iOS shows and tints `window` with it.
    /// Call at launch, before the interface reads the accent.
    public func applyAccent(to window: UIWindow) {
        AppIconAccent.setCurrent(currentOption.accent)
        window.tintColor = AppIconAccent.current.color
    }

    /// Changes the Home Screen icon. iOS confirms the change with its own alert.
    /// On success, the accent follows the new icon in every window.
    public func set(_ option: AppIconOption) async throws {
        try await iconAccess.setAlternateIconName(option.alternateIconName)
        logger.info("App icon: changed to \(option.id)")

        AppIconAccent.setCurrent(option.accent)
        updateWindowsTintColor()
        AppIconChanges.alternateIconNames.send(option.alternateIconName)
    }

    // MARK: Private

    private let iconAccess: AlternateIconAccess
    private let bundle: SystemBundle

    private var declaresAlternateIcons: Bool {
        let icons = bundle.infoValue(forKey: "CFBundleIcons") as? [String: Any]
        let alternateIcons = icons?["CFBundleAlternateIcons"] as? [String: Any]
        return !(alternateIcons ?? [:]).isEmpty
    }

    private func updateWindowsTintColor() {
        let windows = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            window.tintColor = AppIconAccent.current.color
        }
    }
}

/// Every `AppIconService` shares the icon iOS shows, so changes reach observers of any instance.
@MainActor
private enum AppIconChanges {
    static let alternateIconNames = PassthroughSubject<String?, Never>()
}
