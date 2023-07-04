//
//  SelectedTranslationsPreferences.swift
//
//
//  Created by Afifi, Mohamed on 10/30/21.
//

import Foundation
import Preferences
import QuranText

public class SelectedTranslationsPreferences {
    // MARK: Lifecycle

    private init() {}

    // MARK: Public

    public static let shared = SelectedTranslationsPreferences()

    @Preference(selectedTranslations)
    public var selectedTranslations: [Translation.ID]

    public func remove(_ translationId: Int) {
        if let index = selectedTranslations.firstIndex(of: translationId) {
            selectedTranslations.remove(at: index)
        }
    }

    public func isSelected(_ translationId: Translation.ID) -> Bool {
        selectedTranslations.contains(translationId)
    }

    public func toggleSelection(_ translationId: Translation.ID) {
        if let index = selectedTranslations.firstIndex(of: translationId) {
            selectedTranslations.remove(at: index)
        } else {
            selectedTranslations.append(translationId)
        }
    }

    // MARK: Internal

    func reset() {
        for key in [Self.selectedTranslations.key] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

    // MARK: Private

    private static let selectedTranslations = PreferenceKey<[Translation.ID]>(key: "selectedTranslations", defaultValue: [])
}
