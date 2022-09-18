//
//  SelectedTranslationsPreferences.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import Preferences

public class SelectedTranslationsPreferences {
    public static let shared = SelectedTranslationsPreferences()
    private init() {}

    private static let selectedTranslations = PreferenceKey<[Int]>(key: "selectedTranslations", defaultValue: [])

    @Preference(selectedTranslations)
    public var selectedTranslations: [Int]

    public func isSelected(_ translationId: Int) -> Bool {
        selectedTranslations.contains(translationId)
    }

    public func toggleSelection(_ translationId: Int) {
        if let index = selectedTranslations.firstIndex(of: translationId) {
            selectedTranslations.remove(at: index)
        } else {
            selectedTranslations.append(translationId)
        }
    }
}
