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

    public func themedSecondaryForeground() -> some View {
        modifier(ThemeSecondaryForegroundStyle())
    }

    public func themedSecondaryBackground() -> some View {
        modifier(ThemeSecondaryBackgroundStyle())
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

private struct ThemeSecondaryForegroundStyle: ViewModifier {
    @Environment(\.themeStyle) var themeStyle

    func body(content: Content) -> some View {
        content
            .foregroundColor(Color(themeStyle.secondaryTextColor))
    }
}

private struct ThemeSecondaryBackgroundStyle: ViewModifier {
    @Environment(\.themeStyle) var themeStyle

    func body(content: Content) -> some View {
        content
            .background(Color(themeStyle.secondaryBackgroundColor))
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
    public var themeStyle: ThemeStyle {
        get { return self[ThemeStyleKey.self]
        } set { self[ThemeStyleKey.self] = newValue }
    }
}

// MARK: - Theme Style Values

private extension UIColor {
    static let themeCalmSecondaryText: UIColor = .themeCalmText.secondaryLabelVariant()
    static let themeCalmSecondaryBackground: UIColor = .themeCalmBackground.secondaryBackgroundVariant()
    static let themeCalmPageSeparatorBackground: UIColor = .themeCalmBackground.pageSeparatorBackgroundVariant()
    static let themeCalmPageSeparatorLine: UIColor = .themeCalmBackground.pageSeparatorLineVariant()

    static let themeFocusSecondaryText: UIColor = .themeFocusText.secondaryLabelVariant()
    static let themeFocusSecondaryBackground: UIColor = .themeFocusBackground.secondaryBackgroundVariant()
    static let themeFocusPageSeparatorBackground: UIColor = .themeFocusBackground.pageSeparatorBackgroundVariant()
    static let themeFocusPageSeparatorLine: UIColor = .themeFocusBackground.pageSeparatorLineVariant()

    static let themeOriginalSecondaryText: UIColor = .themeOriginalText.secondaryLabelVariant()
    static let themeOriginalSecondaryBackground: UIColor = .themeOriginalBackground.secondaryBackgroundVariant()
    static let themeOriginalPageSeparatorBackground: UIColor = .themeOriginalBackground.pageSeparatorBackgroundVariant()
    static let themeOriginalPageSeparatorLine: UIColor = .themeOriginalBackground.pageSeparatorLineVariant()

    static let themePaperSecondaryText: UIColor = .themePaperText.secondaryLabelVariant()
    static let themePaperSecondaryBackground: UIColor = .themePaperBackground.secondaryBackgroundVariant()
    static let themePaperPageSeparatorBackground: UIColor = .themePaperBackground.pageSeparatorBackgroundVariant()
    static let themePaperPageSeparatorLine: UIColor = .themePaperBackground.pageSeparatorLineVariant()

    static let themeQuietSecondaryText: UIColor = .themeQuietText.secondaryLabelVariant()
    static let themeQuietSecondaryBackground: UIColor = .themeQuietBackground.secondaryBackgroundVariant()
    static let themeQuietPageSeparatorBackground: UIColor = .themeQuietBackground.pageSeparatorBackgroundVariant()
    static let themeQuietPageSeparatorLine: UIColor = .themeQuietBackground.pageSeparatorLineVariant()
}

extension ThemeStyle {
    var textColor: UIColor {
        switch self {
        case .calm: .themeCalmText
        case .focus: .themeFocusText
        case .original: .themeOriginalText
        case .paper: .themePaperText
        case .quiet: .themeQuietText
        }
    }

    var secondaryTextColor: UIColor {
        switch self {
        case .calm: .themeCalmSecondaryText
        case .focus: .themeFocusSecondaryText
        case .original: .themeOriginalSecondaryText
        case .paper: .themePaperSecondaryText
        case .quiet: .themeQuietSecondaryText
        }
    }

    var backgroundColor: UIColor {
        switch self {
        case .calm: .themeCalmBackground
        case .focus: .themeFocusBackground
        case .original: .themeOriginalBackground
        case .paper: .themePaperBackground
        case .quiet: .themeQuietBackground
        }
    }

    var secondaryBackgroundColor: UIColor {
        switch self {
        case .calm: .themeCalmSecondaryBackground
        case .focus: .themeFocusSecondaryBackground
        case .original: .themeOriginalSecondaryBackground
        case .paper: .themePaperSecondaryBackground
        case .quiet: .themeQuietSecondaryBackground
        }
    }

    var pageSeparatorBackground: UIColor {
        switch self {
        case .calm: .themeCalmPageSeparatorBackground
        case .focus: .themeFocusPageSeparatorBackground
        case .original: .themeOriginalPageSeparatorBackground
        case .paper: .themePaperPageSeparatorBackground
        case .quiet: .themeQuietPageSeparatorBackground
        }
    }

    var pageSeparatorLine: UIColor {
        switch self {
        case .calm: .themeCalmPageSeparatorLine
        case .focus: .themeFocusPageSeparatorLine
        case .original: .themeOriginalPageSeparatorLine
        case .paper: .themePaperPageSeparatorLine
        case .quiet: .themeQuietPageSeparatorLine
        }
    }
}
