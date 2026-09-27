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
    private let window = SystemUserInterfaceStyleObserverWindow.shared

    init() {
        userInterfaceStyle = window.traitCollection.userInterfaceStyle
        appearanceMode = themeService.appearanceMode
        themeService.appearanceModePublisher.assign(to: &$appearanceMode)
        window.traitCollectionChangesPublisher.map(\.userInterfaceStyle).assign(to: &$userInterfaceStyle)
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

class SystemUserInterfaceStyleObserverWindow: UIWindow {
    static let shared: SystemUserInterfaceStyleObserverWindow = {
        let window = SystemUserInterfaceStyleObserverWindow(frame: .zero)
        window.isHidden = true
        return window
    }()

    let traitCollectionChangesPublisher = PassthroughSubject<UITraitCollection, Never>()

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        traitCollectionChangesPublisher.send(traitCollection)
    }
}
