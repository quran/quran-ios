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

    public var theme: Theme {
        get { preferenceTheme }
        set {
            guard newValue != preferenceTheme else {
                return
            }
            preferenceTheme = newValue
            let newInterfaceStyle = newValue.userInterfaceStyle
            let windows = UIApplication.shared.windows
            for window in windows {
                window.overrideUserInterfaceStyle = newInterfaceStyle
            }
        }
    }

    public var themePublisher: AnyPublisher<Theme, Never> {
        $preferenceTheme
    }

    // MARK: Private

    private static let themeRaw = PreferenceKey<Int?>(key: "theme", defaultValue: nil)
    private static let themeTransformer = PreferenceTransformer<Int?, Theme>(
        rawToValue: { $0.flatMap { Theme(rawValue: $0) } ?? .auto },
        valueToRaw: { $0.rawValue }
    )

    @TransformedPreference(themeRaw, transformer: themeTransformer)
    private var preferenceTheme: Theme
}

public enum Theme: Int, CustomStringConvertible {
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

extension Theme {
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
