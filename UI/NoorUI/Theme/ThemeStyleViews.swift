//
//  ThemeStyleViews.swift
//  QuranEngine
//
//  Created by Mohamed Afifi on 2025-03-29.
//

import SwiftUI

extension View {
    public func themedBackground() -> some View {
        modifier(ThemeBackgroundStyle())
    }

    public func themedForeground() -> some View {
        modifier(ThemeForegroundStyle())
    }

    public func populateThemeStyle() -> some View {
        modifier(ThemeStylePopulator())
    }
}

private struct ThemeBackgroundStyle: ViewModifier {
    @Environment(\.themeStyle) var themeStyle

    func body(content: Content) -> some View {
        content
            .background(Color(themeStyle.backgroundColor))
    }
}

private struct ThemeForegroundStyle: ViewModifier {
    @Environment(\.themeStyle) var themeStyle

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(themeStyle.textColor))
    }
}

// MARK: - Populate

private struct ThemeStylePopulator: ViewModifier {
    @StateObject private var viewModel = ThemeStylePopulatorViewModel()

    func body(content: Content) -> some View {
        content
            .environment(\.themeStyle, viewModel.themeStyle)
    }
}

@MainActor
private final class ThemeStylePopulatorViewModel: ObservableObject {
    @Published var themeStyle: ThemeStyle
    private let themeService = ThemeService.shared

    init() {
        themeStyle = themeService.themeStyle
        themeService.themeStylePublisher.assign(to: &$themeStyle)
    }
}

// MARK: - Environment Key

private struct ThemeStyleKey: EnvironmentKey {
    static let defaultValue: ThemeStyle = .quiet
}

extension EnvironmentValues {
    var themeStyle: ThemeStyle {
        get { return self[ThemeStyleKey.self]
        } set { self[ThemeStyleKey.self] = newValue }
    }
}

// MARK: - Theme Style Values

private extension ThemeStyle {
    var textColor: UIColor {
        switch self {
        case .calm:
            return .themeCalmText
        case .focus:
            return .themeFocusText
        case .original:
            return .themeOriginalText
        case .paper:
            return .themePaperText
        case .quiet:
            return .themeQuietText
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .calm:
            return .themeCalmBackground
        case .focus:
            return .themeFocusBackground
        case .original:
            return .themeOriginalBackground
        case .paper:
            return .themePaperBackground
        case .quiet:
            return .themeQuietBackground
        }
    }
}
