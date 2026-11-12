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
    /// Arabic uses Arabic-Indic digits unless the locale picks another numbering system, the whole phone
    /// picks `numbers=latn`, or its region has its own Arabic data (such as `ar_SA` or `ar_MA`), whose
    /// default applies. A per-app language may inherit `numbers=latn` from the phone's other language,
    /// so Arabic ignores it and other languages drop it.
    func fixedLocaleNumbers() -> Locale {
        fixedLocaleNumbers(systemLanguages: Self.systemPreferredLanguages, appLanguages: Self.appPreferredLanguages)
    }

    static var fixedCurrentLocaleNumbers: Locale {
        current.fixedLocaleNumbers()
    }
}

extension Locale {
    // MARK: Internal

    /// On the whole phone (the app languages equal the system's, or the primary system language has
    /// this locale's language), `numbers=latn` is the user's own choice.
    ///
    /// - Parameters:
    ///   - systemLanguages: The phone's preferred languages, ignoring any per-app language.
    ///   - appLanguages: The app's preferred languages, including any per-app language.
    func fixedLocaleNumbers(systemLanguages: [String], appLanguages: [String]) -> Locale {
        if #available(iOS 16, *), numberingSystem.identifier != Self.latinNumbers {
            return self
        }
        var components = Locale.components(fromIdentifier: identifier)
        let numbers = components[Self.numbersKey]
        guard numbers == nil || numbers == Self.latinNumbers else {
            return self
        }
        if numbers == Self.latinNumbers, isWholePhone(systemLanguages: systemLanguages, appLanguages: appLanguages) {
            return self
        }

        if isArabicLanguage {
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
        guard #available(iOS 16, *) else {
            return Locale(identifier: Locale.identifier(fromComponents: components))
        }
        // Unlike the identifier, these keep the user's preferences, such as 24-hour time.
        var localeComponents = Locale.Components(locale: self)
        localeComponents.numberingSystem = components[Self.numbersKey].map { Locale.NumberingSystem($0) }
        return Locale(components: localeComponents)
    }

    // MARK: Private

    // Changing either language list relaunches the app, so they're read once.
    private static let systemPreferredLanguages: [String] =
        CFPreferencesCopyAppValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication) as? [String] ?? []

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

    private func isWholePhone(systemLanguages: [String], appLanguages: [String]) -> Bool {
        guard let systemLanguage = systemLanguages.first else {
            return false
        }
        return appLanguages == systemLanguages || Locale(identifier: systemLanguage).languageCode == languageCode
    }
}
