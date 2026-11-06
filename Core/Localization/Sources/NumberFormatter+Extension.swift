//
//  NumberFormatter+Extension.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/1/16.
//
//  Quran for iOS is a Quran reading application for iOS.
//  Copyright (C) 2017  Quran.com
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import Foundation

extension NumberFormatter {
    @nonobjc
    public func format(_ number: NSNumber) -> String {
        string(from: number) ?? number.description
    }

    @nonobjc
    public func format(_ number: Int) -> String {
        format(NSNumber(value: number))
    }

    @nonobjc
    public func format(_ number: Double) -> String {
        format(NSNumber(value: number))
    }

    @nonobjc
    public func format(_ number: Float) -> String {
        format(NSNumber(value: number))
    }

    public static let shared: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = formatter.locale?.fixedLocaleNumbers()
        return formatter
    }()

    public static var arabicNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "ar-SA")
        return formatter
    }()
}

public extension Locale {
    /// Returns the locale used to display numbers.
    ///
    /// When the whole phone is set up in this locale's language, the locale is returned unchanged.
    /// That respects region defaults and any number format the user picked, matching the rest of iOS.
    /// It's the whole phone when the app has no per-app language (its preferred languages equal the
    /// system's), or when the primary system language is this locale's language.
    ///
    /// Otherwise the language comes from a per-app language (Settings › Apps › Quran › Language), and
    /// any `numbers=latn` was inherited from the phone's other language:
    /// - Arabic keeps an explicit non-Latin numbering system. In a region with its own Arabic data
    ///   (for example `ar_SA` or `ar_MA`), it uses that region's default digits. Elsewhere (for example
    ///   `ar_CA` or `ar_US`, whose default is Latin), it uses Arabic-Indic digits.
    /// - Other languages drop an explicit `numbers=latn` and use their default numbering system.
    ///
    /// The system and app languages are read once, because changing either relaunches the app.
    /// Changing the number format doesn't relaunch it, so the receiver (such as `Locale.current`)
    /// is not cached here.
    func fixedLocaleNumbers() -> Locale {
        fixedLocaleNumbers(systemLanguages: Self.systemPreferredLanguages, appLanguages: Self.appPreferredLanguages)
    }

    static var fixedCurrentLocaleNumbers: Locale {
        current.fixedLocaleNumbers()
    }
}

extension Locale {
    // MARK: Internal

    /// - Parameters:
    ///   - systemLanguages: The phone's preferred languages, ignoring any per-app language.
    ///   - appLanguages: The app's preferred languages, including any per-app language.
    func fixedLocaleNumbers(systemLanguages: [String], appLanguages: [String]) -> Locale {
        if let systemLanguage = systemLanguages.first,
           appLanguages == systemLanguages || Locale(identifier: systemLanguage).languageCode == languageCode
        {
            return self
        }
        if #available(iOS 16, *), numberingSystem.identifier != Self.latinNumbers {
            return self
        }

        var components = Locale.components(fromIdentifier: identifier)
        let numbers = components[Self.numbersKey]
        if isArabicLanguage {
            guard numbers == nil || numbers == Self.latinNumbers else {
                return self
            }
            if Self.arabicRegions.contains(Self.numbersRegion(of: components) ?? "") {
                guard numbers == Self.latinNumbers else {
                    return self
                }
                components[Self.numbersKey] = nil
            } else {
                components[Self.numbersKey] = "arab"
            }
        } else {
            guard numbers == Self.latinNumbers else {
                return self
            }
            components[Self.numbersKey] = nil
        }
        return Locale(identifier: Locale.identifier(fromComponents: components))
    }

    // MARK: Private

    /// The phone's preferred languages, ignoring any per-app language.
    private static let systemPreferredLanguages: [String] =
        CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String] ?? []

    /// The app's preferred languages, starting with any per-app language.
    private static let appPreferredLanguages = Locale.preferredLanguages

    private static let numbersKey = "numbers"
    private static let latinNumbers = "latn"

    /// Regions with their own Arabic locale data, such as `SA` or `MA`.
    private static let arabicRegions: Set<String> = Set(Locale.availableIdentifiers.compactMap { identifier in
        let components = Locale.components(fromIdentifier: identifier)
        guard components[NSLocale.Key.languageCode.rawValue] == "ar",
              components[NSLocale.Key.scriptCode.rawValue] == nil,
              let region = components[NSLocale.Key.countryCode.rawValue],
              region.allSatisfy(\.isLetter)
        else {
            return nil
        }
        return region
    })

    /// The region whose defaults decide the digits: the `rg` override when present, else the locale's region.
    private static func numbersRegion(of components: [String: String]) -> String? {
        if let regionOverride = components["rg"], regionOverride.count >= 2 {
            return regionOverride.prefix(2).uppercased()
        }
        return components[NSLocale.Key.countryCode.rawValue]
    }
}
