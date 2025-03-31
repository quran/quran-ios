//
//  ThemeService.swift
//  Quran
//
//  Created by Afifi, Mohamed on 4/7/20.
//  Copyright © 2020 Quran.com. All rights reserved.
//

import Combine
import Preferences
import UIKit

@MainActor
public class ThemeService {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = ThemeService()

    public var appearanceMode: AppearanceMode {
        get { preferenceAppearanceMode }
        set {
            guard newValue != preferenceAppearanceMode else {
                return
            }
            preferenceAppearanceMode = newValue
            updateUserInterfaceStyle(themeStyle: themeStyle, appearanceMode: appearanceMode)
        }
    }

    public var themeStyle: ThemeStyle {
        get { preferenceThemeStyle }
        set {
            guard newValue != preferenceThemeStyle else {
                return
            }
            preferenceThemeStyle = newValue
            updateUserInterfaceStyle(themeStyle: newValue, appearanceMode: appearanceMode)
        }
    }

    public var appearanceModePublisher: AnyPublisher<AppearanceMode, Never> {
        $preferenceAppearanceMode
    }

    public var themeStylePublisher: AnyPublisher<ThemeStyle, Never> {
        $preferenceThemeStyle
    }

    // MARK: Private

    private static let appearanceModeRaw = PreferenceKey<Int?>(key: "theme", defaultValue: nil)
    private static let appearanceModeTransformer = PreferenceTransformer<Int?, AppearanceMode>(
        rawToValue: { $0.flatMap { AppearanceMode(rawValue: $0) } ?? .auto },
        valueToRaw: { $0.rawValue }
    )

    @TransformedPreference(appearanceModeRaw, transformer: appearanceModeTransformer)
    private var preferenceAppearanceMode: AppearanceMode

    private static let themeStyleRaw = PreferenceKey<Int?>(key: "themeStyle", defaultValue: nil)
    private static let themeStyleTransformer = PreferenceTransformer<Int?, ThemeStyle>(
        rawToValue: { $0.flatMap { ThemeStyle(rawValue: $0) } ?? .paper },
        valueToRaw: { $0.rawValue }
    )

    @TransformedPreference(themeStyleRaw, transformer: themeStyleTransformer)
    private var preferenceThemeStyle: ThemeStyle

    private func updateUserInterfaceStyle(themeStyle: ThemeStyle, appearanceMode: AppearanceMode) {
        let newInterfaceStyle = themeStyle == .quiet ? .dark : appearanceMode.userInterfaceStyle
        let windows = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
        for window in windows {
            window.overrideUserInterfaceStyle = newInterfaceStyle
        }
    }
}

public enum AppearanceMode: Int, CustomStringConvertible {
    case light = 0
    case dark = 1
    case auto = 2

    // MARK: Public

    public var description: String {
        switch self {
        case .light: return "light"
        case .dark: return "dark"
        case .auto: return "auto"
        }
    }
}

public enum ThemeStyle: Int {
    case calm
    case focus
    case original
    case paper
    case quiet
}

extension AppearanceMode {
    public var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .auto:
            return .unspecified
        }
    }
}
