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

    public func select(_ id: Translation.ID) {
        if !selectedTranslations.contains(id) {
            selectedTranslations.append(id)
        }
    }

    public func deselect(_ id: Translation.ID) {
        if let index = selectedTranslations.firstIndex(of: id) {
            selectedTranslations.remove(at: index)
        }
    }

    // MARK: Internal

    func reset() {
        Preferences.shared.removeValueForKey(Self.selectedTranslations)
    }

    // MARK: Private

    private static let selectedTranslations = PreferenceKey<[Translation.ID]>(key: "selectedTranslations", defaultValue: [])
}
