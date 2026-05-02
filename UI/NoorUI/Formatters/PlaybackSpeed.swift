//
//  PlaybackSpeed.swift
//
//
//  Created by Mohamed Afifi on 2026-05-02.
//

import Foundation
import Localization

public enum PlaybackSpeed {
  public static let supportedRates: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current.fixedLocaleNumbers()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    public static func formatted(_ rate: Float) -> String {
        formatter.format(rate) + "×"
    }
}
