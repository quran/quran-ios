//
//  AnalyticsUserPropertyValue.swift
//
//
//  Created by Mohamed Afifi on 2026-10-20.
//

import Foundation

/// Values aren't displayed, so they use ASCII digits in every locale.
public enum AnalyticsUserPropertyValue {
    // MARK: Public

    public static let maxLength = 36

    public static func onOff(_ isOn: Bool) -> String {
        isOn ? "on" : "off"
    }

    public static func yesNo(_ isYes: Bool) -> String {
        isYes ? "yes" : "no"
    }

    public static func countBucket(_ count: Int) -> String {
        switch count {
        case ...0: "0"
        case 1: "1"
        case 2: "2"
        default: "3+"
        }
    }

    /// Two decimals at most, one at least: `1.0`, `1.25`, `1.5`.
    public static func decimal(_ value: Double) -> String {
        var text = String(format: "%.2f", locale: posixLocale, value)
        while text.hasSuffix("0"), !text.hasSuffix(".0") {
            text.removeLast()
        }
        return text
    }

    public static func limited(_ value: String) -> String {
        String(value.prefix(maxLength))
    }

    // MARK: Private

    private static let posixLocale = Locale(identifier: "en_US_POSIX")
}
