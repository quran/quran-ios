//
//  AppearanceModeViews.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-31.
//

import Combine
import SwiftUI

extension View {
    public func appearanceModeColorSchema() -> some View {
        modifier(AppearanceModeColorSchema())
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

private struct AppearanceModeColorSchema: ViewModifier {
    @StateObject private var viewModel = AppearanceModeColorSchemaViewModel()

    func body(content: Content) -> some View {
        if let colorSchema = viewModel.colorSchema {
            content
                .environment(\.colorScheme, colorSchema)
        } else {
            content
        }
    }
}

private class SystemUserInterfaceStyleObserverWindow: UIWindow {
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
