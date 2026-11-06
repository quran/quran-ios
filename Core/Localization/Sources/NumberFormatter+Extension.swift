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
    /// A locale that already uses a non-Latin numbering system is returned unchanged.
    /// Arabic uses Arabic-Indic digits when it would otherwise show Latin digits, either
    /// by default (for example `ar_CA`) or through an explicit `numbers=latn`.
    /// Other locales drop an explicit `numbers=latn` and use their default numbering system.
    func fixedLocaleNumbers() -> Locale {
        let numbersKey = "numbers"
        let latinNumbers = "latn"
        if #available(iOS 16, *), numberingSystem.identifier != latinNumbers {
            return self
        }

        var components = Locale.components(fromIdentifier: identifier)
        let numbers = components[numbersKey]
        if isArabicLanguage {
            guard numbers == nil || numbers == latinNumbers else {
                return self
            }
            components[numbersKey] = "arab"
        } else {
            guard numbers == latinNumbers else {
                return self
            }
            components[numbersKey] = nil
        }
        return Locale(identifier: Locale.identifier(fromComponents: components))
    }

    static var fixedCurrentLocaleNumbers: Locale {
        current.fixedLocaleNumbers()
    }
}
