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
        formatter.locale = Locale(identifier: "ar")
        return formatter
    }()
}

public extension Locale {
    func fixedLocaleNumbers() -> Locale {
        let latinSuffix = "@numbers=latn"
        if identifier.hasSuffix(latinSuffix) {
            let localId = identifier.replacingOccurrences(of: latinSuffix, with: "")
            return Locale(identifier: localId)
        } else {
            return self
        }
    }

    static var fixedCurrentLocaleNumbers: Locale {
        current.fixedLocaleNumbers()
    }
}
