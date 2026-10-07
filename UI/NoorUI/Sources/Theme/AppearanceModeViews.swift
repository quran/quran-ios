//
//  AppearanceModeViews.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-31.
//

import Combine
import SwiftUI

extension View {
    /// Resolves theme colors with the appearance mode's color scheme without overriding the
    /// subtree's color scheme, so hosted UIKit views keep the window's interface style.
    public func appearanceModeThemeColors() -> some View {
        modifier(AppearanceModeThemeColors())
    }
}

@MainActor
private final class AppearanceModeColorSchemaViewModel: ObservableObject {
    @Published private var appearanceMode: AppearanceMode
    @Published private var userInterfaceStyle: UIUserInterfaceStyle

    private let themeService = ThemeService.shared
    private let systemStyleObserver = SystemUserInterfaceStyleObserver.shared

    init() {
        userInterfaceStyle = systemStyleObserver.userInterfaceStyle
        appearanceMode = themeService.appearanceMode
        themeService.appearanceModePublisher.assign(to: &$appearanceMode)
        systemStyleObserver.$userInterfaceStyle.assign(to: &$userInterfaceStyle)
    }

    var colorSchema: ColorScheme? {
        switch appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .auto:
            switch userInterfaceStyle {
            case .light: return .light
            case .dark: return .dark
            case .unspecified: return nil
            @unknown default: return nil
            }
        }
    }
}

private struct AppearanceModeThemeColors: ViewModifier {
    @StateObject private var viewModel = AppearanceModeColorSchemaViewModel()

    func body(content: Content) -> some View {
        content
            .environment(\.themeColorSchemeOverride, viewModel.colorSchema)
    }
}

/// Reports the system interface style, which the theme's `overrideUserInterfaceStyle` hides from
/// the app's windows. It reads the window scene's traits, which that override doesn't reach.
/// A hidden observer window isn't reliable: on device it missed appearance changes made from
/// Control Center while the reader was open, until the app went to the background.
@MainActor
final class SystemUserInterfaceStyleObserver {
    // MARK: Lifecycle

    private init() {
        observeSceneActivations()
        attachToConnectedScene()
    }

    // MARK: Internal

    static let shared = SystemUserInterfaceStyleObserver()

    @Published private(set) var userInterfaceStyle: UIUserInterfaceStyle = .unspecified

    // MARK: Private

    private weak var windowScene: UIWindowScene?
    private var traitChangeRegistration: Any?
    private var sceneObservers: [NSObjectProtocol] = []

    private func attachToConnectedScene() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive }
            ?? windowScene.flatMap { scenes.contains($0) ? $0 : nil }
            ?? scenes.first
        if scene !== windowScene {
            observeTraitChanges(of: scene)
        }
        // Rereading on activation also covers iOS 15 and 16, which can't observe the scene's traits.
        updateUserInterfaceStyle()
    }

    private func observeTraitChanges(of scene: UIWindowScene?) {
        if #available(iOS 17.0, *) {
            if let registration = traitChangeRegistration as? UITraitChangeRegistration {
                windowScene?.unregisterForTraitChanges(registration)
            }
            traitChangeRegistration = scene?.registerForTraitChanges(
                [UITraitUserInterfaceStyle.self]
            ) { [weak self] (_: UIWindowScene, _: UITraitCollection) in
                self?.updateUserInterfaceStyle()
            }
        }
        windowScene = scene
    }

    private func updateUserInterfaceStyle() {
        let style = windowScene?.traitCollection.userInterfaceStyle ?? .unspecified
        if style != userInterfaceStyle {
            userInterfaceStyle = style
        }
    }

    private func observeSceneActivations() {
        let names = [UIScene.didActivateNotification, UIScene.didDisconnectNotification]
        sceneObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in
                    self?.attachToConnectedScene()
                }
            }
        }
    }
}
